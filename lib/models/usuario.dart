class Usuario {
  final int? idUsuario;
  final String nombre;
  final String apellido;
  final String? email;
  final String? contrasena;
  final int idRol;
  final String? nombreRol;

  Usuario({
    this.idUsuario,
    required this.nombre,
    required this.apellido,
    this.email,
    this.contrasena,
    required this.idRol,
    this.nombreRol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['id_usuario'] as int?,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      email: json['email'] as String?,
      contrasena: json['contrasena'] as String?,
      idRol: json['id_rol'] as int,
      nombreRol: json['nombre_rol'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'contrasena': contrasena,
      'id_rol': idRol,
    };
  }

  String get nombreCompleto => '$nombre $apellido';

  bool get esAdministrador => idRol == 1;
  bool get esVendedor => idRol == 2;
  bool get esCliente => idRol == 3;
}