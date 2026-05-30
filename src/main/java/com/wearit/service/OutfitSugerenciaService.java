package com.wearit.service;

import com.wearit.dto.SugerenciaOutfitDTO;
import com.wearit.model.Prenda;
import com.wearit.repository.PrendaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
public class OutfitSugerenciaService {

    @Autowired
    private PrendaRepository prendaRepository;

    // Colores complementarios para sugerencias por color
    private static final Map<String, List<String>> COLORES_COMPLEMENTARIOS = Map.of(
        "rojo",     Arrays.asList("negro", "blanco", "azul"),
        "azul",     Arrays.asList("blanco", "gris", "beige"),
        "negro",    Arrays.asList("blanco", "rojo", "azul"),
        "blanco",   Arrays.asList("negro", "azul", "gris"),
        "verde",    Arrays.asList("beige", "blanco", "negro"),
        "amarillo", Arrays.asList("negro", "azul", "gris"),
        "rosa",     Arrays.asList("blanco", "negro", "gris"),
        "gris",     Arrays.asList("blanco", "negro", "azul")
    );

    // ── Sugerencias básicas (sin filtro) ────────────────────────────────────

    public List<SugerenciaOutfitDTO> sugerirOutfits(Long usuarioId) {
        List<Prenda> prendas = prendaRepository.findByUsuarioId(usuarioId);
        List<SugerenciaOutfitDTO> sugerencias = new ArrayList<>();

        if (prendas.isEmpty()) return sugerencias;

        List<Prenda> casualOutfit = generarOutfitPorEstilo(prendas, "casual");
        if (casualOutfit.size() >= 2) {
            sugerencias.add(new SugerenciaOutfitDTO(
                "Look Casual", casualOutfit,
                "Combinación casual con prendas de estilo casual"
            ));
        }

        List<Prenda> colorOutfit = generarOutfitPorColor(prendas);
        if (colorOutfit.size() >= 2) {
            sugerencias.add(new SugerenciaOutfitDTO(
                "Look por Colores", colorOutfit,
                "Combinación basada en colores complementarios"
            ));
        }

        List<Prenda> randomOutfit = generarOutfitRandom(prendas);
        if (randomOutfit.size() >= 2) {
            sugerencias.add(new SugerenciaOutfitDTO(
                "Look Aleatorio", randomOutfit,
                "¡Atrévete con esta combinación sorpresa!"
            ));
        }

        return sugerencias;
    }

    // ── Sugerencias filtradas por ocasión y temporada (widget tiempo) ────────

    public List<SugerenciaOutfitDTO> sugerirPorTiempo(
            Long usuarioId, String ocasion, String temporada) {

        List<Prenda> todas = prendaRepository.findByUsuarioId(usuarioId);
        List<SugerenciaOutfitDTO> sugerencias = new ArrayList<>();

        if (todas.isEmpty()) return sugerencias;

        // Filtrar prendas por temporada si se especifica
        List<Prenda> prendas = todas.stream()
            .filter(p -> temporada == null
                || "todo año".equalsIgnoreCase(p.getTemporada())
                || temporada.equalsIgnoreCase(p.getTemporada()))
            .toList();

        if (prendas.isEmpty()) prendas = todas; // fallback sin filtro

        // Si hay ocasión, priorizar ese estilo
        if (ocasion != null && !ocasion.isEmpty()) {
            List<Prenda> porOcasion = generarOutfitPorEstilo(prendas, ocasion);
            if (porOcasion.size() >= 2) {
                sugerencias.add(new SugerenciaOutfitDTO(
                    "Look " + capitalize(ocasion),
                    porOcasion,
                    "Outfit " + ocasion + " adaptado al tiempo actual"
                ));
            }
        }

        // Siempre añadir sugerencia por color
        List<Prenda> colorOutfit = generarOutfitPorColor(prendas);
        if (colorOutfit.size() >= 2) {
            sugerencias.add(new SugerenciaOutfitDTO(
                "Look por Colores",
                colorOutfit,
                temporada != null
                    ? "Combinación de colores para " + temporada
                    : "Combinación basada en colores complementarios"
            ));
        }

        // Aleatorio como comodín
        List<Prenda> randomOutfit = generarOutfitRandom(prendas);
        if (randomOutfit.size() >= 2) {
            sugerencias.add(new SugerenciaOutfitDTO(
                "Look Sorpresa", randomOutfit,
                "¡Prueba esta combinación para hoy!"
            ));
        }

        return sugerencias;
    }

    // ── Métodos privados de generación ───────────────────────────────────────

    private List<Prenda> generarOutfitPorEstilo(List<Prenda> prendas, String estilo) {
        List<Prenda> filtradas = prendas.stream()
            .filter(p -> estilo.equalsIgnoreCase(p.getEstilo()))
            .collect(java.util.stream.Collectors.toCollection(ArrayList::new));

        Collections.shuffle(filtradas);
        return filtradas.subList(0, Math.min(3, filtradas.size()));
    }

    private List<Prenda> generarOutfitPorColor(List<Prenda> prendas) {
        if (prendas.isEmpty()) return List.of();

        List<Prenda> resultado = new ArrayList<>();
        Prenda principal = prendas.get(new Random().nextInt(prendas.size()));
        resultado.add(principal);

        String colorPrincipal = principal.getColor() != null
            ? principal.getColor().toLowerCase() : "";
        List<String> complementarios = COLORES_COMPLEMENTARIOS
            .getOrDefault(colorPrincipal, Arrays.asList("blanco", "negro"));

        for (Prenda p : prendas) {
            if (!p.getId().equals(principal.getId())
                    && p.getColor() != null
                    && complementarios.contains(p.getColor().toLowerCase())
                    && resultado.size() < 3) {
                resultado.add(p);
            }
        }
        return resultado;
    }

    private List<Prenda> generarOutfitRandom(List<Prenda> prendas) {
        List<Prenda> copia = new ArrayList<>(prendas);
        Collections.shuffle(copia);
        return copia.subList(0, Math.min(3, copia.size()));
    }

    private String capitalize(String s) {
        if (s == null || s.isEmpty()) return s;
        return s.substring(0, 1).toUpperCase() + s.substring(1);
    }
}