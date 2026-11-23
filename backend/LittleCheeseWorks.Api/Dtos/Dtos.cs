using System.ComponentModel.DataAnnotations;

namespace LittleCheeseWorks.Api.Dtos;

// Forma única de todas las respuestas de la API (sección 2.3 del documento general)
public class ApiResponse<T>
{
    public bool Exito { get; set; }
    public string Mensaje { get; set; } = "";
    public T? Datos { get; set; }
    public List<string>? Errores { get; set; }

    public static ApiResponse<T> Ok(T datos, string mensaje = "Operación exitosa.") =>
        new() { Exito = true, Mensaje = mensaje, Datos = datos };

    public static ApiResponse<T> Error(string mensaje, List<string>? errores = null) =>
        new() { Exito = false, Mensaje = mensaje, Errores = errores };
}

// ---------- Autenticación ----------
public class RegistroDto
{
    [Required(ErrorMessage = "El nombre es obligatorio.")]
    [StringLength(100, MinimumLength = 2, ErrorMessage = "El nombre debe tener entre 2 y 100 caracteres.")]
    public string Nombre { get; set; } = "";

    [Required(ErrorMessage = "El correo es obligatorio.")]
    [EmailAddress(ErrorMessage = "El correo no tiene un formato válido.")]
    [StringLength(150)]
    public string Email { get; set; } = "";

    [Required(ErrorMessage = "La contraseña es obligatoria.")]
    [StringLength(64, MinimumLength = 8, ErrorMessage = "La contraseña debe tener entre 8 y 64 caracteres.")]
    public string Password { get; set; } = "";
}

public class LoginDto
{
    [Required, EmailAddress] public string Email { get; set; } = "";
    [Required] public string Password { get; set; } = "";
}

public record UsuarioDto(int Id, string Nombre, string Email, string Rol, DateTime FechaCreacion);

public record LoginRespuestaDto(string TokenAcceso, DateTime Expira, UsuarioDto Usuario);

// ---------- Cuartos ----------
public class CuartoGuardarDto
{
    [Required(ErrorMessage = "El nombre del cuarto es obligatorio.")]
    [StringLength(80)]
    public string Nombre { get; set; } = "";

    [Range(0.5, 999.99, ErrorMessage = "El ancho debe ser mayor que 0.")]
    public decimal AnchoM { get; set; }

    [Range(0.5, 999.99, ErrorMessage = "El largo debe ser mayor que 0.")]
    public decimal LargoM { get; set; }

    [Range(0, 999.99)] public decimal BaseX { get; set; }
    [Range(0, 999.99)] public decimal BaseY { get; set; }
}

public record CuartoDto(int Id, string Nombre, decimal AnchoM, decimal LargoM,
    decimal BaseX, decimal BaseY, int TotalPuntos);

// ---------- Puntos guardados ----------
public class PuntoGuardarDto
{
    [Range(1, int.MaxValue, ErrorMessage = "Hay que indicar el cuarto.")]
    public int CuartoId { get; set; }

    [Required(ErrorMessage = "El nombre del punto es obligatorio.")]
    [StringLength(80)]
    public string Nombre { get; set; } = "";

    [Range(0, 999.99)] public decimal X { get; set; }
    [Range(0, 999.99)] public decimal Y { get; set; }
}

public record PuntoDto(int Id, int CuartoId, string Nombre, decimal X, decimal Y, DateTime FechaCreacion);
