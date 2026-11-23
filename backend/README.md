# Backend - El Pequeño Queso Trabaja

API en ASP.NET Core (.NET 10) con Entity Framework Core y PostgreSQL.
Separada en Controllers -> Services -> Repositories.

## Qué tiene (semana 2)

- 7 tablas creadas con la migración `Inicial`: Usuarios, Cuartos, PuntosGuardados, Robots, Entregas, ObjetosDetectados y Alertas.
- Registro e inicio de sesión con contraseña en BCrypt y token JWT de 60 minutos.
- CRUD de cuartos y de puntos guardados. Cada usuario solo ve lo suyo.
- Respuestas con la misma forma (`exito`, `mensaje`, `datos`, `errores`) y middleware de errores.

## Cómo correrlo

```bash
cd backend/LittleCheeseWorks.Api
dotnet user-secrets set "ConnectionStrings:Default" "Host=localhost;Port=5432;Database=littlecheeseworks;Username=postgres;Password=<tu clave>"
dotnet user-secrets set "Jwt:Secret" "<una clave de 32 caracteres o más>"
dotnet run --launch-profile http
```

Al arrancar aplica las migraciones solo. Swagger queda en http://localhost:5150.
