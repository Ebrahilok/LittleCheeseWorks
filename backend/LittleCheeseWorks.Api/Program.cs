using System.Text;
using LittleCheeseWorks.Api.Data;
using LittleCheeseWorks.Api.Dtos;
using LittleCheeseWorks.Api.Middleware;
using LittleCheeseWorks.Api.Repositories;
using LittleCheeseWorks.Api.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;

var builder = WebApplication.CreateBuilder(args);

// ─────────────────────────────────────────────────────────────
// 1. BASE DE DATOS (PostgreSQL con Entity Framework Core)
//    La cadena real va en user-secrets, no en el repositorio.
// ─────────────────────────────────────────────────────────────
builder.Services.AddDbContext<AppDbContext>(o =>
    o.UseNpgsql(builder.Configuration.GetConnectionString("Default")));

// ─────────────────────────────────────────────────────────────
// 2. INYECCIÓN DE DEPENDENCIAS: Controller -> Service -> Repository
// ─────────────────────────────────────────────────────────────
builder.Services.AddScoped<IUsuarioRepository, UsuarioRepository>();
builder.Services.AddScoped<ICuartoRepository, CuartoRepository>();
builder.Services.AddScoped<IPuntoRepository, PuntoRepository>();
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<ICuartoService, CuartoService>();
builder.Services.AddScoped<IPuntoService, PuntoService>();

// ─────────────────────────────────────────────────────────────
// 3. AUTENTICACIÓN JWT
// ─────────────────────────────────────────────────────────────
var jwt = builder.Configuration.GetSection("Jwt");
var secreto = jwt["Secret"];
if (string.IsNullOrWhiteSpace(secreto) || secreto == "VA_EN_USER_SECRETS" || secreto.Length < 32)
    throw new InvalidOperationException(
        "Falta Jwt:Secret. Configúralo con: dotnet user-secrets set \"Jwt:Secret\" \"<clave de 32+ caracteres>\"");

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.RequireHttpsMetadata = false;
        o.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwt["Issuer"],
            ValidAudience = jwt["Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secreto)),
            ClockSkew = TimeSpan.Zero
        };
        // 401 y 403 con el mismo formato JSON que el resto de la API
        o.Events = new JwtBearerEvents
        {
            OnChallenge = async ctx =>
            {
                ctx.HandleResponse();
                ctx.Response.StatusCode = 401;
                await ctx.Response.WriteAsJsonAsync(ApiResponse<object>.Error(
                    string.IsNullOrEmpty(ctx.Error)
                        ? "Falta el token en el encabezado Authorization."
                        : "El token no es válido o ya venció."));
            },
            OnForbidden = async ctx =>
            {
                ctx.Response.StatusCode = 403;
                await ctx.Response.WriteAsJsonAsync(ApiResponse<object>.Error("Tu rol no tiene permiso para esto."));
            }
        };
    });
builder.Services.AddAuthorization();

// Los errores de validación de los DTOs también salen como ApiResponse
builder.Services.AddControllers().ConfigureApiBehaviorOptions(o =>
{
    o.InvalidModelStateResponseFactory = ctx =>
    {
        var errores = ctx.ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage).ToList();
        return new BadRequestObjectResult(ApiResponse<object>.Error("Los datos enviados no son válidos.", errores));
    };
});

// ─────────────────────────────────────────────────────────────
// 4. SWAGGER CON BOTÓN AUTHORIZE PARA EL TOKEN
// ─────────────────────────────────────────────────────────────
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(o =>
{
    o.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "El Pequeño Queso Trabaja - API",
        Version = "v1 (semana 2)",
        Description = "Backend del robot de carga. Semana 2: registro, login con JWT y CRUD de cuartos y puntos.\n\n" +
                      "1. Crea una cuenta en POST /api/auth/registro o entra con POST /api/auth/login.\n" +
                      "2. Copia el tokenAcceso y pégalo en el botón Authorize.\n" +
                      "3. Prueba los endpoints de cuartos y puntos."
    });
    o.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Description = "Pega solo el token, sin la palabra Bearer.",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });
    o.AddSecurityRequirement(doc => new OpenApiSecurityRequirement
    {
        { new OpenApiSecuritySchemeReference("Bearer", doc), new List<string>() }
    });
    var xml = Path.Combine(AppContext.BaseDirectory, "LittleCheeseWorks.Api.xml");
    if (File.Exists(xml)) o.IncludeXmlComments(xml);
});

// La app de Expo corre en otro origen durante el desarrollo
builder.Services.AddCors(o => o.AddDefaultPolicy(p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

// ─────────────────────────────────────────────────────────────
// 5. PIPELINE
// ─────────────────────────────────────────────────────────────
var app = builder.Build();

// Aplica las migraciones pendientes al arrancar
using (var scope = app.Services.CreateScope())
    await scope.ServiceProvider.GetRequiredService<AppDbContext>().Database.MigrateAsync();

app.UseMiddleware<ManejoErroresMiddleware>();
app.UseSwagger();
app.UseSwaggerUI(o =>
{
    o.SwaggerEndpoint("/swagger/v1/swagger.json", "El Pequeño Queso Trabaja v1");
    o.RoutePrefix = string.Empty;
    o.DocumentTitle = "El Pequeño Queso Trabaja - API";
});
app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
