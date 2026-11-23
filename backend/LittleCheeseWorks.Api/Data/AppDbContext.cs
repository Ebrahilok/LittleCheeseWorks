using LittleCheeseWorks.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace LittleCheeseWorks.Api.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Usuario> Usuarios => Set<Usuario>();
    public DbSet<Cuarto> Cuartos => Set<Cuarto>();
    public DbSet<PuntoGuardado> PuntosGuardados => Set<PuntoGuardado>();
    public DbSet<Robot> Robots => Set<Robot>();
    public DbSet<Entrega> Entregas => Set<Entrega>();
    public DbSet<ObjetoDetectado> ObjetosDetectados => Set<ObjetoDetectado>();
    public DbSet<Alerta> Alertas => Set<Alerta>();

    protected override void OnModelCreating(ModelBuilder mb)
    {
        mb.Entity<Usuario>(e =>
        {
            e.ToTable("Usuarios", t =>
                t.HasCheckConstraint("CK_Usuarios_Rol", "\"Rol\" IN ('Operador','Administrador')"));
            e.Property(x => x.Nombre).HasMaxLength(100).IsRequired();
            e.Property(x => x.Email).HasMaxLength(150).IsRequired();
            e.HasIndex(x => x.Email).IsUnique();
            e.Property(x => x.PasswordHash).HasMaxLength(100).IsRequired();
            e.Property(x => x.Rol).HasMaxLength(20).IsRequired();
            e.Property(x => x.FechaCreacion).HasDefaultValueSql("now()");
        });

        mb.Entity<Cuarto>(e =>
        {
            e.ToTable("Cuartos", t =>
            {
                t.HasCheckConstraint("CK_Cuartos_Medidas", "\"AnchoM\" > 0 AND \"LargoM\" > 0");
                t.HasCheckConstraint("CK_Cuartos_Base",
                    "\"BaseX\" BETWEEN 0 AND \"AnchoM\" AND \"BaseY\" BETWEEN 0 AND \"LargoM\"");
            });
            e.Property(x => x.Nombre).HasMaxLength(80).IsRequired();
            e.Property(x => x.AnchoM).HasPrecision(5, 2);
            e.Property(x => x.LargoM).HasPrecision(5, 2);
            e.Property(x => x.BaseX).HasPrecision(5, 2);
            e.Property(x => x.BaseY).HasPrecision(5, 2);
            e.HasOne(x => x.Usuario).WithMany(u => u.Cuartos)
                .HasForeignKey(x => x.UsuarioId).OnDelete(DeleteBehavior.Cascade);
        });

        mb.Entity<PuntoGuardado>(e =>
        {
            e.ToTable("PuntosGuardados");
            e.Property(x => x.Nombre).HasMaxLength(80).IsRequired();
            e.Property(x => x.X).HasPrecision(5, 2);
            e.Property(x => x.Y).HasPrecision(5, 2);
            e.Property(x => x.FechaCreacion).HasDefaultValueSql("now()");
            // El nombre no se puede repetir dentro del mismo cuarto
            e.HasIndex(x => new { x.CuartoId, x.Nombre }).IsUnique();
            e.HasOne(x => x.Cuarto).WithMany(c => c.Puntos)
                .HasForeignKey(x => x.CuartoId).OnDelete(DeleteBehavior.Cascade);
        });

        mb.Entity<Robot>(e =>
        {
            e.ToTable("Robots");
            e.Property(x => x.Nombre).HasMaxLength(80).IsRequired();
            e.HasIndex(x => x.Nombre).IsUnique();
            e.Property(x => x.DireccionIp).HasMaxLength(45);
            e.Property(x => x.Version).HasMaxLength(20);
            e.HasData(new Robot { Id = 1, Nombre = "Queso-01", Version = "simulador", Activo = true });
        });

        mb.Entity<Entrega>(e =>
        {
            e.ToTable("Entregas", t => t.HasCheckConstraint("CK_Entregas_Estado",
                "\"Estado\" IN ('Pendiente','EnRuta','Entregada','Cancelada','Fallida')"));
            e.Property(x => x.DestinoX).HasPrecision(5, 2);
            e.Property(x => x.DestinoY).HasPrecision(5, 2);
            e.Property(x => x.Estado).HasMaxLength(20).IsRequired();
            e.HasOne(x => x.Usuario).WithMany(u => u.Entregas)
                .HasForeignKey(x => x.UsuarioId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.Robot).WithMany()
                .HasForeignKey(x => x.RobotId).OnDelete(DeleteBehavior.Restrict);
            // Si se borra el punto, la entrega sigue en el historial pero sin punto
            e.HasOne(x => x.Punto).WithMany()
                .HasForeignKey(x => x.PuntoId).OnDelete(DeleteBehavior.SetNull);
        });

        mb.Entity<ObjetoDetectado>(e =>
        {
            e.ToTable("ObjetosDetectados");
            e.Property(x => x.X).HasPrecision(5, 2);
            e.Property(x => x.Y).HasPrecision(5, 2);
            e.Property(x => x.Ancho).HasPrecision(4, 2);
            e.Property(x => x.Alto).HasPrecision(4, 2);
            e.HasOne(x => x.Entrega).WithMany(en => en.Objetos)
                .HasForeignKey(x => x.EntregaId).OnDelete(DeleteBehavior.Cascade);
        });

        mb.Entity<Alerta>(e =>
        {
            e.ToTable("Alertas");
            e.Property(x => x.Codigo).HasMaxLength(40).IsRequired();
            e.Property(x => x.Descripcion).HasMaxLength(200).IsRequired();
            e.HasOne(x => x.Robot).WithMany()
                .HasForeignKey(x => x.RobotId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.Entrega).WithMany()
                .HasForeignKey(x => x.EntregaId).OnDelete(DeleteBehavior.SetNull);
        });
    }
}
