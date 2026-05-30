package com.wearit.controller;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import com.wearit.dto.SugerenciaOutfitDTO;
import com.wearit.model.Outfit;
import com.wearit.service.LikeService;
import com.wearit.service.OutfitService;
import com.wearit.service.OutfitSugerenciaService;

@RestController
@RequestMapping("/api/outfits")
public class OutfitController {

    @Autowired private OutfitService outfitService;
    @Autowired private OutfitSugerenciaService sugerenciaService;
    @Autowired private LikeService likeService;

    @GetMapping
    public List<Outfit> listar() {
        return outfitService.listarTodos();
    }

    @GetMapping("/usuario/{usuarioId}")
    public List<Outfit> listarPorUsuario(@PathVariable Long usuarioId) {
        return outfitService.listarPorUsuario(usuarioId);
    }

    @GetMapping("/publicos")
    public Map<String, Object> listarPublicos(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        List<Outfit> todos = outfitService.listarPublicos();
        int inicio = page * size;
        int fin = Math.min(inicio + size, todos.size());
        List<Outfit> pagina = inicio >= todos.size() ? List.of() : todos.subList(inicio, fin);
        return Map.of(
            "content", pagina,
            "totalElements", todos.size(),
            "totalPages", (int) Math.ceil((double) todos.size() / size),
            "number", page
        );
    }

    // Ranking corregido — una query, orden real por likes
    @GetMapping("/ranking")
    public List<Map<String, Object>> getRanking() {
        List<Object[]> rankingIds = likeService.getRankingIds();
        List<Map<String, Object>> resultado = new ArrayList<>();

        for (Object[] row : rankingIds) {
            Long outfitId = (Long) row[0];
            Long totalLikes = (Long) row[1];
            try {
                Outfit outfit = outfitService.buscarPorId(outfitId);
                resultado.add(Map.of(
                    "id", outfit.getId(),
                    "nombre", outfit.getNombre() != null ? outfit.getNombre() : "",
                    "ocasion", outfit.getOcasion() != null ? outfit.getOcasion() : "",
                    "esPublico", outfit.getEsPublico(),
                    "prendas", outfit.getPrendas(),
                    "likes", totalLikes
                ));
            } catch (Exception ignored) {}
        }
        return resultado.stream().limit(10).toList();
    }

    @GetMapping("/{id}")
    public Outfit buscarPorId(@PathVariable Long id) {
        return outfitService.buscarPorId(id);
    }

    @PostMapping
    public Outfit crear(@RequestBody Outfit outfit) {
        return outfitService.crear(outfit);
    }

    @PutMapping("/{id}")
    public Outfit actualizar(@PathVariable Long id, @RequestBody Outfit datos) {
        return outfitService.actualizar(id, datos);
    }

    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable Long id) {
        outfitService.eliminar(id);
    }

    @GetMapping("/sugerir/{usuarioId}")
    public List<SugerenciaOutfitDTO> sugerirOutfits(@PathVariable Long usuarioId) {
        return sugerenciaService.sugerirOutfits(usuarioId);
    }

    @GetMapping("/sugerir/{usuarioId}/tiempo")
    public List<SugerenciaOutfitDTO> sugerirPorTiempo(
            @PathVariable Long usuarioId,
            @RequestParam(required = false) String ocasion,
            @RequestParam(required = false) String temporada) {
        return sugerenciaService.sugerirPorTiempo(usuarioId, ocasion, temporada);
    }
}
