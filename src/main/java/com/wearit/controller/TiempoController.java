package com.wearit.controller;

import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Scanner;

import org.json.JSONArray;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/tiempo")
public class TiempoController {

    @Value("${openweather.api.key}")
    private String apiKey;

    // ── Tiempo actual (sin cambios) ──────────────────────────────────────────
    @GetMapping("/{ciudad}")
    public Map<String, Object> getTiempo(@PathVariable String ciudad) throws Exception {
        String url = "https://api.openweathermap.org/data/2.5/weather?q="
                + ciudad + "&appid=" + apiKey + "&units=metric&lang=es";

        JSONObject json = fetchJson(url);

        double temp = json.getJSONObject("main").getDouble("temp");
        String desc = json.getJSONArray("weather").getJSONObject(0).getString("description");
        String icono = "https://openweathermap.org/img/wn/"
                + json.getJSONArray("weather").getJSONObject(0).getString("icon") + "@2x.png";
        String temporada = getTemporada(temp);

        return Map.of(
            "ciudad", ciudad,
            "temperatura", temp,
            "descripcion", desc,
            "icono", icono,
            "temporadaRecomendada", temporada
        );
    }

    // ── Forecast 5 días — endpoint gratuito de OpenWeatherMap ────────────────
    // Devuelve una entrada por día (mediodía) con temp min/max, descripción e icono
    @GetMapping("/{ciudad}/forecast")
    public List<Map<String, Object>> getForecast(@PathVariable String ciudad) throws Exception {
        // forecast/daily no está en el plan gratuito — usamos forecast cada 3h
        // y agrupamos por día tomando el slot más cercano a las 12:00
        String url = "https://api.openweathermap.org/data/2.5/forecast?q="
                + ciudad + "&appid=" + apiKey + "&units=metric&lang=es&cnt=40";

        JSONObject json = fetchJson(url);
        JSONArray lista = json.getJSONArray("list");

        // Agrupamos por fecha (primeros 5 días distintos)
        List<Map<String, Object>> resultado = new ArrayList<>();
        String ultimaFecha = "";

        for (int i = 0; i < lista.length(); i++) {
            JSONObject slot = lista.getJSONObject(i);
            String dtTxt = slot.getString("dt_txt"); // "2026-05-28 12:00:00"
            String fecha = dtTxt.substring(0, 10);
            String hora  = dtTxt.substring(11, 13);

            // Solo tomamos el slot de las 12:00 de cada día (o el primero si no hay)
            if (!fecha.equals(ultimaFecha) && (hora.equals("12") || i == 0)) {
                ultimaFecha = fecha;

                double temp    = slot.getJSONObject("main").getDouble("temp");
                double tempMin = slot.getJSONObject("main").getDouble("temp_min");
                double tempMax = slot.getJSONObject("main").getDouble("temp_max");
                String desc    = slot.getJSONArray("weather")
                                     .getJSONObject(0).getString("description");
                String icono   = "https://openweathermap.org/img/wn/"
                                 + slot.getJSONArray("weather")
                                       .getJSONObject(0).getString("icon") + "@2x.png";

                resultado.add(Map.of(
                    "fecha",       fecha,
                    "temperatura", temp,
                    "tempMin",     tempMin,
                    "tempMax",     tempMax,
                    "descripcion", desc,
                    "icono",       icono,
                    "temporada",   getTemporada(temp)
                ));

                if (resultado.size() == 5) break; // máximo 5 días
            }
        }

        return resultado;
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private JSONObject fetchJson(String urlStr) throws Exception {
        HttpURLConnection conn = (HttpURLConnection) new URL(urlStr).openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(5000);
        Scanner sc = new Scanner(conn.getInputStream());
        StringBuilder sb = new StringBuilder();
        while (sc.hasNext()) sb.append(sc.nextLine());
        sc.close();
        return new JSONObject(sb.toString());
    }

    private String getTemporada(double temp) {
        if (temp > 20) return "verano";
        if (temp > 10) return "primavera";
        return "invierno";
    }
}