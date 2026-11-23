using System.Security.Claims;
using LittleCheeseWorks.Api.Dtos;
using LittleCheeseWorks.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LittleCheeseWorks.Api.Controllers;

// Los controllers solo reciben la petición y regresan la respuesta HTTP.
// Las reglas viven en los services.

public abstract class BaseController : ControllerBase
{
    // Id del usuario que viene dentro del token JWT
    protected int UsuarioId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}

[ApiController]
[Route("api/auth")]
[Tags("1. Autenticación")]
public class AuthController(IAuthService auth) : BaseController
{
    /// <summary>Crea una cuenta nueva con rol Operador.</summary>
    [HttpPost("registro")]
    public async Task<ActionResult<ApiResponse<UsuarioDto>>> Registro(RegistroDto dto)
    {
        var usuario = await auth.RegistrarAsync(dto);
        return StatusCode(201, ApiResponse<UsuarioDto>.Ok(usuario, "Cuenta creada."));
    }

    /// <summary>Revisa correo y contraseña y regresa el token JWT (60 minutos).</summary>
    [HttpPost("login")]
    public async Task<ActionResult<ApiResponse<LoginRespuestaDto>>> Login(LoginDto dto) =>
        Ok(ApiResponse<LoginRespuestaDto>.Ok(await auth.LoginAsync(dto), "Sesión iniciada."));

    /// <summary>Datos del usuario dueño del token.</summary>
    [Authorize]
    [HttpGet("perfil")]
    public async Task<ActionResult<ApiResponse<UsuarioDto>>> Perfil() =>
        Ok(ApiResponse<UsuarioDto>.Ok(await auth.PerfilAsync(UsuarioId)));
}

[ApiController]
[Authorize]
[Route("api/cuartos")]
[Tags("2. Cuartos")]
public class CuartosController(ICuartoService servicio) : BaseController
{
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<CuartoDto>>>> Listar() =>
        Ok(ApiResponse<List<CuartoDto>>.Ok(await servicio.ListarAsync(UsuarioId)));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResponse<CuartoDto>>> Obtener(int id) =>
        Ok(ApiResponse<CuartoDto>.Ok(await servicio.ObtenerAsync(id, UsuarioId)));

    [HttpPost]
    public async Task<ActionResult<ApiResponse<CuartoDto>>> Crear(CuartoGuardarDto dto)
    {
        var cuarto = await servicio.CrearAsync(dto, UsuarioId);
        return CreatedAtAction(nameof(Obtener), new { id = cuarto.Id },
            ApiResponse<CuartoDto>.Ok(cuarto, "Cuarto creado."));
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<ApiResponse<CuartoDto>>> Editar(int id, CuartoGuardarDto dto) =>
        Ok(ApiResponse<CuartoDto>.Ok(await servicio.EditarAsync(id, dto, UsuarioId), "Cuarto actualizado."));

    [HttpDelete("{id:int}")]
    public async Task<ActionResult<ApiResponse<object>>> Eliminar(int id)
    {
        await servicio.EliminarAsync(id, UsuarioId);
        return Ok(ApiResponse<object>.Ok(new { id }, "Cuarto eliminado junto con sus puntos."));
    }
}

[ApiController]
[Authorize]
[Route("api/puntos")]
[Tags("3. Puntos guardados")]
public class PuntosController(IPuntoService servicio) : BaseController
{
    /// <summary>Lista los puntos del usuario. Se puede filtrar por cuarto.</summary>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<PuntoDto>>>> Listar([FromQuery] int? cuartoId) =>
        Ok(ApiResponse<List<PuntoDto>>.Ok(await servicio.ListarAsync(UsuarioId, cuartoId)));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResponse<PuntoDto>>> Obtener(int id) =>
        Ok(ApiResponse<PuntoDto>.Ok(await servicio.ObtenerAsync(id, UsuarioId)));

    [HttpPost]
    public async Task<ActionResult<ApiResponse<PuntoDto>>> Crear(PuntoGuardarDto dto)
    {
        var punto = await servicio.CrearAsync(dto, UsuarioId);
        return CreatedAtAction(nameof(Obtener), new { id = punto.Id },
            ApiResponse<PuntoDto>.Ok(punto, "Punto guardado."));
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<ApiResponse<PuntoDto>>> Editar(int id, PuntoGuardarDto dto) =>
        Ok(ApiResponse<PuntoDto>.Ok(await servicio.EditarAsync(id, dto, UsuarioId), "Punto actualizado."));

    [HttpDelete("{id:int}")]
    public async Task<ActionResult<ApiResponse<object>>> Eliminar(int id)
    {
        await servicio.EliminarAsync(id, UsuarioId);
        return Ok(ApiResponse<object>.Ok(new { id }, "Punto eliminado."));
    }
}
