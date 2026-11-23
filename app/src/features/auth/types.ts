export interface Usuario {
  id: number;
  nombre: string;
  email: string;
  rol: 'Operador' | 'Administrador';
}

/** 'api' = sesión real con el backend; 'demo' = sin servidor, todo se guarda en el teléfono. */
export type ModoSesion = 'api' | 'demo';

export interface Sesion {
  modo: ModoSesion;
  usuario: Usuario;
  token: string | null;
  expira: string | null;
}

export interface LoginDto {
  email: string;
  password: string;
}

export interface RegistroDto extends LoginDto {
  nombre: string;
}
