using LittleCheeseWorks.Api.Dtos;
using LittleCheeseWorks.Api.Middleware;
using LittleCheeseWorks.Api.Models;
using LittleCheeseWorks.Api.Repositories;

namespace LittleCheeseWorks.Api.Services;

public interface ICuartoService
{
    Task<List<CuartoDto>> ListarAsync(int usuarioId);
    Task<CuartoDto> ObtenerAsync(int id, int usuarioId);
    Task<CuartoDto> CrearAsync(CuartoGuardarDto dto, int usuarioId);
    Task<CuartoDto> EditarAsync(int id, CuartoGuardarDto dto, int usuarioId);
    Task EliminarAsync(int id, int usuarioId);
}

public class CuartoService(ICuartoRepository cuartos) : ICuartoService
{
    public async Task<List<CuartoDto>> ListarAsync(int usuarioId) =>
        (await cuartos.ListarPorUsuarioAsync(usuarioId)).Select(ADto).ToList();

    public async Task<CuartoDto> ObtenerAsync(int id, int usuarioId) =>
        ADto(await BuscarAsync(id, usuarioId));

    public async Task<CuartoDto> CrearAsync(CuartoGuardarDto dto, int usuarioId)
    {
        ValidarBase(dto);
        var cuarto = new Cuarto { UsuarioId = usuarioId };
        Copiar(dto, cuarto);
        await cuartos.AgregarAsync(cuarto);
        return ADto(cuarto);
    }

    public async Task<CuartoDto> EditarAsync(int id, CuartoGuardarDto dto, int usuarioId)
    {
        ValidarBase(dto);
        var cuarto = await BuscarAsync(id, usuarioId);

        // Si el cuarto se hace más chico, ningún punto guardado puede quedar afuera
        var fuera = cuarto.Puntos.Where(p => p.X > dto.AnchoM || p.Y > dto.LargoM).Select(p => p.Nombre).ToList();
        if (fuera.Count > 0)
            throw ReglaNegocioException.Invalido(
                $"Con esas medidas quedarían fuera del cuarto los puntos: {string.Join(", ", fuera)}.");

        Copiar(dto, cuarto);
        await cuartos.GuardarCambiosAsync();
        return ADto(cuarto);
    }

    public async Task EliminarAsync(int id, int usuarioId) =>
        await cuartos.EliminarAsync(await BuscarAsync(id, usuarioId));

    private async Task<Cuarto> BuscarAsync(int id, int usuarioId) =>
        await cuartos.ObtenerAsync(id, usuarioId) ?? throw ReglaNegocioException.NoEncontrado("El cuarto");

    // La base del robot tiene que estar dentro del cuarto
    private static void ValidarBase(CuartoGuardarDto dto)
    {
        if (dto.BaseX > dto.AnchoM || dto.BaseY > dto.LargoM)
            throw ReglaNegocioException.Invalido("La base del robot tiene que quedar dentro del cuarto.");
    }

    private static void Copiar(CuartoGuardarDto dto, Cuarto c)
    {
        c.Nombre = dto.Nombre.Trim();
        c.AnchoM = dto.AnchoM;
        c.LargoM = dto.LargoM;
        c.BaseX = dto.BaseX;
        c.BaseY = dto.BaseY;
    }

    private static CuartoDto ADto(Cuarto c) =>
        new(c.Id, c.Nombre, c.AnchoM, c.LargoM, c.BaseX, c.BaseY, c.Puntos.Count);
}

public interface IPuntoService
{
    Task<List<PuntoDto>> ListarAsync(int usuarioId, int? cuartoId);
    Task<PuntoDto> ObtenerAsync(int id, int usuarioId);
    Task<PuntoDto> CrearAsync(PuntoGuardarDto dto, int usuarioId);
    Task<PuntoDto> EditarAsync(int id, PuntoGuardarDto dto, int usuarioId);
    Task EliminarAsync(int id, int usuarioId);
}

public class PuntoService(IPuntoRepository puntos, ICuartoRepository cuartos) : IPuntoService
{
    public async Task<List<PuntoDto>> ListarAsync(int usuarioId, int? cuartoId) =>
        (await puntos.ListarAsync(usuarioId, cuartoId)).Select(ADto).ToList();

    public async Task<PuntoDto> ObtenerAsync(int id, int usuarioId) =>
        ADto(await BuscarAsync(id, usuarioId));

    public async Task<PuntoDto> CrearAsync(PuntoGuardarDto dto, int usuarioId)
    {
        var cuarto = await ValidarAsync(dto, usuarioId, null);
        var punto = new PuntoGuardado { CuartoId = cuarto.Id, Nombre = dto.Nombre.Trim(), X = dto.X, Y = dto.Y };
        await puntos.AgregarAsync(punto);
        return ADto(punto);
    }

    public async Task<PuntoDto> EditarAsync(int id, PuntoGuardarDto dto, int usuarioId)
    {
        var punto = await BuscarAsync(id, usuarioId);
        var cuarto = await ValidarAsync(dto, usuarioId, id);
        punto.CuartoId = cuarto.Id;
        punto.Nombre = dto.Nombre.Trim();
        punto.X = dto.X;
        punto.Y = dto.Y;
        await puntos.GuardarCambiosAsync();
        return ADto(punto);
    }

    public async Task EliminarAsync(int id, int usuarioId) =>
        await puntos.EliminarAsync(await BuscarAsync(id, usuarioId));

    private async Task<PuntoGuardado> BuscarAsync(int id, int usuarioId) =>
        await puntos.ObtenerAsync(id, usuarioId) ?? throw ReglaNegocioException.NoEncontrado("El punto");

    // Reglas del punto: el cuarto es del usuario, las coordenadas caen dentro
    // y el nombre no se repite en ese cuarto
    private async Task<Cuarto> ValidarAsync(PuntoGuardarDto dto, int usuarioId, int? idActual)
    {
        var cuarto = await cuartos.ObtenerAsync(dto.CuartoId, usuarioId)
                     ?? throw ReglaNegocioException.NoEncontrado("El cuarto");

        if (dto.X > cuarto.AnchoM || dto.Y > cuarto.LargoM)
            throw ReglaNegocioException.Invalido(
                $"El punto queda fuera del cuarto ({cuarto.AnchoM} x {cuarto.LargoM} m).");

        if (await puntos.ExisteNombreAsync(cuarto.Id, dto.Nombre.Trim(), idActual))
            throw ReglaNegocioException.Conflicto($"Ya hay un punto llamado \"{dto.Nombre.Trim()}\" en este cuarto.");

        return cuarto;
    }

    private static PuntoDto ADto(PuntoGuardado p) => new(p.Id, p.CuartoId, p.Nombre, p.X, p.Y, p.FechaCreacion);
}
