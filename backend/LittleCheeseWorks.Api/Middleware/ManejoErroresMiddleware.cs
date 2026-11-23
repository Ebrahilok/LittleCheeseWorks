using LittleCheeseWorks.Api.Dtos;

namespace LittleCheeseWorks.Api.Middleware;

// Excepción que lanzan los services cuando no se cumple una regla del sistema.
// Lleva el código HTTP que debe ver la app (400, 404, 409...).
public class ReglaNegocioException(int codigo, string mensaje) : Exception(mensaje)
{
    public int Codigo { get; } = codigo;

    public static ReglaNegocioException NoEncontrado(string que) => new(404, $"{que} no existe o no es tuyo.");
    public static ReglaNegocioException Conflicto(string mensaje) => new(409, mensaje);
    public static ReglaNegocioException Invalido(string mensaje) => new(400, mensaje);
}

// Atrapa cualquier excepción y la convierte en un ApiResponse con el código correcto,
// así la app siempre puede leer el campo "mensaje".
public class ManejoErroresMiddleware(RequestDelegate next, ILogger<ManejoErroresMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (ReglaNegocioException ex)
        {
            context.Response.StatusCode = ex.Codigo;
            await context.Response.WriteAsJsonAsync(ApiResponse<object>.Error(ex.Message));
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error no controlado en {Ruta}", context.Request.Path);
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            await context.Response.WriteAsJsonAsync(
                ApiResponse<object>.Error("Ocurrió un error inesperado en el servidor."));
        }
    }
}
