/// Datos de conexión a Supabase.
/// La clave "publishable" es pública por diseño: la seguridad la dan
/// las reglas (RLS) de la base de datos, no esta clave.
class AppConfig {
  static const supabaseUrl = 'https://dyidtromvllhmnbamppd.supabase.co';
  static const supabaseKey = 'sb_publishable_e1XQ4Yp2fesI-EnSwW4sIQ_7ke4EczE';

  static const emailFarmacia = 'wrctech.sistemas+farmacia@gmail.com';
  static const emailTecnico = 'wrctech.sistemas+tecnico@gmail.com';
  static const emailFarmaceutico = 'wrctech.sistemas+farmaceutico@gmail.com';
}
