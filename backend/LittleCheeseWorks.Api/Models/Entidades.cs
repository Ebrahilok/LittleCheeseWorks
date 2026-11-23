namespace LittleCheeseWorks.Api.Models;

// Las 7 tablas del diagrama entidad-relación de la semana 1.

public static class Roles
{
    public const string Operador = "Operador";
    public const string Administrador = "Administrador";
}

public static class EstadosEntrega
{
    public const string Pendiente = "Pendiente";
    public const string EnRuta = "EnRuta";
    public const string Entregada = "Entregada";
    public const string Cancelada = "Cancelada";
    public const string Fallida = "Fallida";
}

public class Usuario
{
    public int Id { get; set; }
    public string Nombre { get; set; } = "";
    public string Email { get; set; } = "";
    public string PasswordHash { get; set; } = "";
    public string Rol { get; set; } = Roles.Operador;
    public bool Activo { get; set; } = true;
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

    public List<Cuarto> Cuartos { get; set; } = [];
    public List<Entrega> Entregas { get; set; } = [];
}

public class Cuarto
{
    public int Id { get; set; }
    public int UsuarioId { get; set; }
    public string Nombre { get; set; } = "";
    public decimal AnchoM { get; set; }
    public decimal LargoM { get; set; }
    public decimal BaseX { get; set; }
    public decimal BaseY { get; set; }

    public Usuario? Usuario { get; set; }
    public List<PuntoGuardado> Puntos { get; set; } = [];
}

public class PuntoGuardado
{
    public int Id { get; set; }
    public int CuartoId { get; set; }
    public string Nombre { get; set; } = "";
    public decimal X { get; set; }
    public decimal Y { get; set; }
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

    public Cuarto? Cuarto { get; set; }
}

public class Robot
{
    public int Id { get; set; }
    public string Nombre { get; set; } = "";
    public string? DireccionIp { get; set; }
    public string? Version { get; set; }
    public bool Activo { get; set; } = true;
}

public class Entrega
{
    public int Id { get; set; }
    public int UsuarioId { get; set; }
    public int RobotId { get; set; }
    public int? PuntoId { get; set; }
    public decimal DestinoX { get; set; }
    public decimal DestinoY { get; set; }
    public string Estado { get; set; } = EstadosEntrega.Pendiente;
    public DateTime FechaInicio { get; set; } = DateTime.UtcNow;
    public DateTime? FechaFin { get; set; }

    public Usuario? Usuario { get; set; }
    public Robot? Robot { get; set; }
    public PuntoGuardado? Punto { get; set; }
    public List<ObjetoDetectado> Objetos { get; set; } = [];
}

public class ObjetoDetectado
{
    public int Id { get; set; }
    public int EntregaId { get; set; }
    public decimal X { get; set; }
    public decimal Y { get; set; }
    public decimal Ancho { get; set; }
    public decimal Alto { get; set; }
    public DateTime FechaDeteccion { get; set; } = DateTime.UtcNow;

    public Entrega? Entrega { get; set; }
}

public class Alerta
{
    public int Id { get; set; }
    public int RobotId { get; set; }
    public int? EntregaId { get; set; }
    public string Codigo { get; set; } = "";
    public string Descripcion { get; set; } = "";
    public DateTime Fecha { get; set; } = DateTime.UtcNow;
    public bool Atendida { get; set; }

    public Robot? Robot { get; set; }
    public Entrega? Entrega { get; set; }
}
