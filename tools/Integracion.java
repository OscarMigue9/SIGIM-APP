import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

public class Integracion {

    private static final String DEFAULT_URL = System.getenv("SUPABASE_URL");
    private static final String DEFAULT_ANON_KEY = System.getenv("SUPABASE_ANON_KEY");

    public static String fetchPedidos(String supabaseUrl, String supabaseAnonKey) throws IOException, InterruptedException {
        if (supabaseUrl == null || supabaseAnonKey == null) {
            throw new IllegalArgumentException("Faltan SUPABASE_URL o SUPABASE_ANON_KEY");
        }

        String select = "id_producto,cantidad,precio_unitario,pedido:pedido(id_pedido,fecha_creacion,id_cliente,id_cliente_contacto,estado_pedido:estado_pedido(nombre_estado),cliente:usuario!pedido_id_cliente_fkey(nombre,apellido),contacto:cliente_contacto!pedido_id_cliente_contacto_fkey(nombre,apellido)),producto:producto!detalle_pedido_id_producto_fkey(nombre)";
        String url = supabaseUrl + "/rest/v1/detalle_pedido?select=" + select;

        HttpClient client = HttpClient.newHttpClient();
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("apikey", supabaseAnonKey)
                .header("Authorization", "Bearer " + supabaseAnonKey)
                .header("Prefer", "return=representation")
                .GET()
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() >= 200 && response.statusCode() < 300) {
            return response.body();
        } else {
            throw new IOException("HTTP " + response.statusCode() + ": " + response.body());
        }
    }

    public static void main(String[] args) {
        try {
            String json = fetchPedidos(DEFAULT_URL, DEFAULT_ANON_KEY);
            System.out.println(json);
        } catch (Exception e) {
            e.printStackTrace();
            System.err.println("Error llamando a Supabase: " + e.getMessage());
            System.exit(1);
        }
    }
}
