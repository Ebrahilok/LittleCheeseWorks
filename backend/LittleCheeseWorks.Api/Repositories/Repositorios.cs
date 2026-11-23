using LittleCheeseWorks.Api.Data;
using LittleCheeseWorks.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace LittleCheeseWorks.Api.Repositories;

// Los repositories son la única capa que toca la base de datos.

public interface IUsuarioRepository
{
    Task<Usuario?> ObtenerPorEmailAsync(string email);
    Task<Usuario?> ObtenerPorIdAsync(int id);
    Task<bool> ExisteEmailAsync(string email);
    Task AgregarAsync(Usuario usuario);
}

public class UsuarioRepository(AppDbContext db) : IUsuarioRepository
{
    public Task<Usuario?> ObtenerPorEmailAsync(string email) =>
        db.Usuarios.FirstOrDefaultAsync(u => u.Email == email);

    public Task<Usuario?> ObtenerPorIdAsync(int id) =>
        db.Usuarios.AsNoTracking().FirstOrDefaultAsync(u => u.Id == id);

    public Task<bool> ExisteEmailAsync(string email) =>
        db.Usuarios.AnyAsync(u => u.Email == email);

    public async Task AgregarAsync(Usuario usuario)
    {
        db.Usuarios.Add(usuario);
        await db.SaveChangesAsync();
    }
}

public interface ICuartoRepository
{
    Task<List<Cuarto>> ListarPorUsuarioAsync(int usuarioId);
    Task<Cuarto?> ObtenerAsync(int id, int usuarioId);
    Task AgregarAsync(Cuarto cuarto);
    Task GuardarCambiosAsync();
    Task EliminarAsync(Cuarto cuarto);
}

public class CuartoRepository(AppDbContext db) : ICuartoRepository
{
    // Siempre se filtra por el usuario del token: nadie ve cuartos de otra persona
    public Task<List<Cuarto>> ListarPorUsuarioAsync(int usuarioId) =>
        db.Cuartos.Include(c => c.Puntos)
            .Where(c => c.UsuarioId == usuarioId)
            .OrderBy(c => c.Nombre)
            .ToListAsync();

    public Task<Cuarto?> ObtenerAsync(int id, int usuarioId) =>
        db.Cuartos.Include(c => c.Puntos)
            .FirstOrDefaultAsync(c => c.Id == id && c.UsuarioId == usuarioId);

    public async Task AgregarAsync(Cuarto cuarto)
    {
        db.Cuartos.Add(cuarto);
        await db.SaveChangesAsync();
    }

    public Task GuardarCambiosAsync() => db.SaveChangesAsync();

    public async Task EliminarAsync(Cuarto cuarto)
    {
        db.Cuartos.Remove(cuarto);
        await db.SaveChangesAsync();
    }
}

public interface IPuntoRepository
{
    Task<List<PuntoGuardado>> ListarAsync(int usuarioId, int? cuartoId);
    Task<PuntoGuardado?> ObtenerAsync(int id, int usuarioId);
    Task<bool> ExisteNombreAsync(int cuartoId, string nombre, int? excluirId = null);
    Task AgregarAsync(PuntoGuardado punto);
    Task GuardarCambiosAsync();
    Task EliminarAsync(PuntoGuardado punto);
}

public class PuntoRepository(AppDbContext db) : IPuntoRepository
{
    public Task<List<PuntoGuardado>> ListarAsync(int usuarioId, int? cuartoId) =>
        db.PuntosGuardados.AsNoTracking()
            .Where(p => p.Cuarto!.UsuarioId == usuarioId && (cuartoId == null || p.CuartoId == cuartoId))
            .OrderBy(p => p.Nombre)
            .ToListAsync();

    public Task<PuntoGuardado?> ObtenerAsync(int id, int usuarioId) =>
        db.PuntosGuardados.Include(p => p.Cuarto)
            .FirstOrDefaultAsync(p => p.Id == id && p.Cuarto!.UsuarioId == usuarioId);

    public Task<bool> ExisteNombreAsync(int cuartoId, string nombre, int? excluirId = null) =>
        db.PuntosGuardados.AnyAsync(p => p.CuartoId == cuartoId
            && p.Nombre.ToLower() == nombre.ToLower()
            && (excluirId == null || p.Id != excluirId));

    public async Task AgregarAsync(PuntoGuardado punto)
    {
        db.PuntosGuardados.Add(punto);
        await db.SaveChangesAsync();
    }

    public Task GuardarCambiosAsync() => db.SaveChangesAsync();

    public async Task EliminarAsync(PuntoGuardado punto)
    {
        db.PuntosGuardados.Remove(punto);
        await db.SaveChangesAsync();
    }
}
