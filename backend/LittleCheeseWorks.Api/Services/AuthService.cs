using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using LittleCheeseWorks.Api.Dtos;
using LittleCheeseWorks.Api.Middleware;
using LittleCheeseWorks.Api.Models;
using LittleCheeseWorks.Api.Repositories;
using Microsoft.IdentityModel.Tokens;

namespace LittleCheeseWorks.Api.Services;

public interface ITokenService
{
    (string token, DateTime expira) GenerarToken(Usuario usuario);
}

public class TokenService(IConfiguration config) : ITokenService
{
    public (string token, DateTime expira) GenerarToken(Usuario usuario)
    {
        var jwt = config.GetSection("Jwt");
        var llave = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["Secret"]!));
        var expira = DateTime.UtcNow.AddMinutes(jwt.GetValue("MinutosVigencia", 60));

        // El token lleva el id y el rol; con eso los services filtran los datos de cada usuario
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, usuario.Id.ToString()),
            new Claim(ClaimTypes.Email, usuario.Email),
            new Claim(ClaimTypes.Name, usuario.Nombre),
            new Claim(ClaimTypes.Role, usuario.Rol)
        };

        var token = new JwtSecurityToken(
            issuer: jwt["Issuer"],
            audience: jwt["Audience"],
            claims: claims,
            expires: expira,
            signingCredentials: new SigningCredentials(llave, SecurityAlgorithms.HmacSha256));

        return (new JwtSecurityTokenHandler().WriteToken(token), expira);
    }
}

public interface IAuthService
{
    Task<UsuarioDto> RegistrarAsync(RegistroDto dto);
    Task<LoginRespuestaDto> LoginAsync(LoginDto dto);
    Task<UsuarioDto> PerfilAsync(int usuarioId);
}

public class AuthService(IUsuarioRepository usuarios, ITokenService tokens) : IAuthService
{
    public async Task<UsuarioDto> RegistrarAsync(RegistroDto dto)
    {
        var email = dto.Email.Trim().ToLowerInvariant();
        if (await usuarios.ExisteEmailAsync(email))
            throw ReglaNegocioException.Conflicto("Ya existe una cuenta con ese correo.");

        // RF-02: toda cuenta nueva es Operador; solo un administrador puede cambiarlo
        var usuario = new Usuario
        {
            Nombre = dto.Nombre.Trim(),
            Email = email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
            Rol = Roles.Operador
        };
        await usuarios.AgregarAsync(usuario);
        return AUsuarioDto(usuario);
    }

    public async Task<LoginRespuestaDto> LoginAsync(LoginDto dto)
    {
        var usuario = await usuarios.ObtenerPorEmailAsync(dto.Email.Trim().ToLowerInvariant());

        // Mismo mensaje si falla el correo o la contraseña, para no dar pistas
        if (usuario is null || !BCrypt.Net.BCrypt.Verify(dto.Password, usuario.PasswordHash))
            throw new ReglaNegocioException(401, "Correo o contraseña incorrectos.");
        if (!usuario.Activo)
            throw new ReglaNegocioException(403, "La cuenta está desactivada.");

        var (token, expira) = tokens.GenerarToken(usuario);
        return new LoginRespuestaDto(token, expira, AUsuarioDto(usuario));
    }

    public async Task<UsuarioDto> PerfilAsync(int usuarioId)
    {
        var usuario = await usuarios.ObtenerPorIdAsync(usuarioId)
                      ?? throw ReglaNegocioException.NoEncontrado("El usuario");
        return AUsuarioDto(usuario);
    }

    private static UsuarioDto AUsuarioDto(Usuario u) => new(u.Id, u.Nombre, u.Email, u.Rol, u.FechaCreacion);
}
