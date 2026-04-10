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

    // Mapa de colores complementarios
    private static final Map<String, List<String>> COLORES_COMPLEMENTARIOS = Map.of(
        "rojo", Arrays.asList("negro", "blanco", "azul"),
        "azul", Arrays.asList("blanco", "gris", "beige"),
        "negro", Arrays.asList("blanco", "rojo", "azul"),
        "blanco", Arrays.asList("negro", "azul", "gris"),
        "verde", Arrays.asList("beige", "blanco", "negro"),
        "amarillo", Arrays.asList("negro", "azul", "gris"),
        "rosa", Arrays.asList("blanco", "negro", "gris"),
        "gris", Arrays.asList("blanco", "negro", "azul")
    );

    public List<SugerenciaOutfitDTO> sugerirOutfits(Long usuarioId) {
        List<Prenda> prendas = prendaRepository.findByUsuarioId(usuarioId);
        List<SugerenciaOutfitDTO> sugerencias = new ArrayList<>();

        if (prendas.isEmpty()) {
            return sugerencias;
        }

        // Agrupar prendas por tipo
        Map<String, List<Prenda>> prendasPorTipo = new HashMap<>();
        for (Prenda p : prendas) {
            prendasPorTipo.computeIfAbsent(p.getTipo(), k -> new ArrayList<>()).add(p);
        }

        // Sugerencia 1: Casual
        List<Prenda> casualOutfit = generarOutfitPorEstilo(prendas, "casual");
        if (casualOutfit.size() >= 2) {
            sugerencias.add(new SugerenciaOutfitDTO(
                "Look Casual",
                casualOutfit,
                "Combinación casual con prendas de estilo casual"
            ));
        }

        // Sugerencia 2: Combinación de colores
        List<Prenda> colorOutfit = generarOutfitPorColor(prendas);
        if (colorOutfit.size() >= 2) {
            sugerencias.add(new SugerenciaOutfitDTO(
                "Look por Colores",
                colorOutfit,
                "Combinación basada en colores complementarios"
            ));
        }

        // Sugerencia 3: Random (mezcla)
        List<Prenda> randomOutfit = generarOutfitRandom(prendas);
        if (randomOutfit.size() >= 2) {
            sugerencias.add(new SugerenciaOutfitDTO(
                "Look Aleatorio",
                randomOutfit,
                "¡Atrévete con esta combinación sorpresa!"
            ));
        }

        return sugerencias;
    }

    private List<Prenda> generarOutfitPorEstilo(List<Prenda> prendas, String estilo) {
        List<Prenda> prendasEstilo = new ArrayList<>();
        for (Prenda p : prendas) {
            if (estilo.equalsIgnoreCase(p.getEstilo())) {
                prendasEstilo.add(p);
            }
        }
        
        // Seleccionar hasta 3 prendas
        List<Prenda> resultado = new ArrayList<>();
        Collections.shuffle(prendasEstilo);
        for (int i = 0; i < Math.min(3, prendasEstilo.size()); i++) {
            resultado.add(prendasEstilo.get(i));
        }
        return resultado;
    }

    private List<Prenda> generarOutfitPorColor(List<Prenda> prendas) {
        List<Prenda> resultado = new ArrayList<>();
        
        // Tomar una prenda principal
        if (prendas.isEmpty()) return resultado;
        
        Prenda principal = prendas.get(new Random().nextInt(prendas.size()));
        resultado.add(principal);
        
        String colorPrincipal = principal.getColor().toLowerCase();
        List<String> complementarios = COLORES_COMPLEMENTARIOS.getOrDefault(colorPrincipal, 
            Arrays.asList("blanco", "negro"));
        
        // Buscar prendas con colores complementarios
        for (Prenda p : prendas) {
            if (p.getId() != principal.getId() && 
                complementarios.contains(p.getColor().toLowerCase()) && 
                resultado.size() < 3) {
                resultado.add(p);
            }
        }
        
        return resultado;
    }

    private List<Prenda> generarOutfitRandom(List<Prenda> prendas) {
        List<Prenda> resultado = new ArrayList<>();
        List<Prenda> copia = new ArrayList<>(prendas);
        Collections.shuffle(copia);
        
        for (int i = 0; i < Math.min(3, copia.size()); i++) {
            resultado.add(copia.get(i));
        }
        return resultado;
    }
}