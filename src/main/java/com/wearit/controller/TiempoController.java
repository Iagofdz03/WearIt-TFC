package com.wearit.controller;

import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Map;
import java.util.Scanner;

import org.json.JSONObject;  
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/tiempo")
public class TiempoController {

    @Value("${openweather.api.key}")
    private String apiKey;

    @GetMapping("/{ciudad}")
    public Map<String, Object> getTiempo(@PathVariable String ciudad) throws Exception {
        String url = "https://api.openweathermap.org/data/2.5/weather?q="
                + ciudad + "&appid=" + apiKey + "&units=metric&lang=es";

        HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
        conn.setRequestMethod("GET");

        Scanner sc = new Scanner(conn.getInputStream());
        StringBuilder sb = new StringBuilder();
        while (sc.hasNext()) sb.append(sc.nextLine());
        sc.close();

        JSONObject json = new JSONObject(sb.toString());
        double temp = json.getJSONObject("main").getDouble("temp");
        String desc = json.getJSONArray("weather").getJSONObject(0).getString("description");
        String icono = "https://openweathermap.org/img/wn/"
                + json.getJSONArray("weather").getJSONObject(0).getString("icon") + "@2x.png";
        String temporada = temp > 20 ? "verano" : temp > 10 ? "primavera" : "invierno";

        return Map.of(
            "ciudad", ciudad,
            "temperatura", temp,
            "descripcion", desc,
            "icono", icono,
            "temporadaRecomendada", temporada
        );
    }
}