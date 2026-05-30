package com.wearit.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import java.util.Map;

@Service
public class TiempoService {

    @Value("${openweather.api.key}")
    private String apiKey;

    private final RestTemplate restTemplate = new RestTemplate();

    public Map<String, Object> getTiempo(String ciudad) {
        String url = "https://api.openweathermap.org/data/2.5/weather" +
                     "?q=" + ciudad +
                     "&appid=" + apiKey +
                     "&units=metric" +
                     "&lang=es";

        Map response = restTemplate.getForObject(url, Map.class);

        Map main = (Map) response.get("main");
        Map weather = (Map) ((java.util.List) response.get("weather")).get(0);

        double temperatura = ((Number) main.get("temp")).doubleValue();
        String descripcion = (String) weather.get("description");
        String icono = (String) weather.get("icon");

        return Map.of(
            "ciudad", ciudad,
            "temperatura", temperatura,
            "descripcion", descripcion,
            "icono", "https://openweathermap.org/img/wn/" + icono + "@2x.png",
            "temporadaRecomendada", getTemporadaRecomendada(temperatura)
        );
    }

    private String getTemporadaRecomendada(double temperatura) {
        if (temperatura >= 25) return "verano";
        if (temperatura >= 15) return "primavera";
        if (temperatura >= 5)  return "otoño";
        return "invierno";
    }
}