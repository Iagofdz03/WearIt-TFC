package com.wearit.controller;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import com.wearit.dto.SugerenciaOutfitDTO;
import com.wearit.model.Outfit;
import com.wearit.model.Prenda;
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
    public List<Map<String, Object>> listarPorUsuario(@PathVariable Long usuarioId) {
        return outfitService.listarPorUsuario(usuarioId)
            .stream()
            .map(this::enriquecerOutfit)
            .toList();
    }
    
    

    // Devuelve outfits públicos con info del creador incluida
    @GetMapping("/publicos")
    public Map<String, Object> listarPublicos(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        List<Outfit> todos = outfitService.listarPublicos();
        int inicio = page * size;
        int fin = Math.min(inicio + size, todos.size());
        List<Outfit> pagina = inicio >= todos.size()
            ? List.of() : todos.subList(inicio, fin);

        // Enriquecer con datos del creador y likes
        List<Map<String, Object>> enriquecidos = new ArrayList<>();
        for (Outfit o : pagina) {
            enriquecidos.add(enriquecerOutfit(o));
        }

        return Map.of(
            "content", enriquecidos,
            "totalElements", todos.size(),
            "totalPages", (int) Math.ceil((double) todos.size() / size),
            "number", page
        );
    }

    // Ranking por likes con info completa
    @GetMapping("/ranking")
    public List<Map<String, Object>> getRanking() {
        List<Object[]> rankingIds = likeService.getRankingIds();
        List<Map<String, Object>> resultado = new ArrayList<>();
        for (Object[] row : rankingIds) {
            Long outfitId = (Long) row[0];
            Long totalLikes = (Long) row[1];
            try {
                Outfit outfit = outfitService.buscarPorId(outfitId);
                Map<String, Object> data = new HashMap<>(enriquecerOutfit(outfit));
                data.put("likes", totalLikes);
                resultado.add(data);
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

    @GetMapping("/usuario/{usuarioId}/sugerencias")
    public List<SugerenciaOutfitDTO> sugerirOutfits(
            @PathVariable Long usuarioId,
            @RequestParam(required = false) String ocasion,
            @RequestParam(required = false) String temporada) {

        if (ocasion != null || temporada != null) {
            return sugerenciaService.sugerirOutfitsConFiltros(usuarioId, ocasion, temporada);
        }
        return sugerenciaService.sugerirOutfits(usuarioId);
    }

    @GetMapping("/sugerir/{usuarioId}/tiempo")
    public List<SugerenciaOutfitDTO> sugerirPorTiempo(
            @PathVariable Long usuarioId,
            @RequestParam(required = false) String ocasion,
            @RequestParam(required = false) String temporada) {
        return sugerenciaService.sugerirPorTiempo(usuarioId, ocasion, temporada);
    }

    // Enriquece un outfit con nombre del creador y número de likes
    private Map<String, Object> enriquecerOutfit(Outfit outfit) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", outfit.getId());
        map.put("nombre", outfit.getNombre() != null ? outfit.getNombre() : "");
        map.put("ocasion", outfit.getOcasion() != null ? outfit.getOcasion() : "");
        map.put("esPublico", outfit.getEsPublico());
        map.put("fechaCreacion", outfit.getFechaCreacion() != null
            ? outfit.getFechaCreacion().toString() : "");
        map.put("likes", likeService.contarPorOutfit(outfit.getId()));
        map.put("fotoPortada", outfit.getFotoPortada() != null ? outfit.getFotoPortada() : "");

        // Datos del creador
        if (outfit.getUsuario() != null) {
            map.put("creadorId", outfit.getUsuario().getId());
            map.put("creadorNombre", outfit.getUsuario().getNombre() != null
                ? outfit.getUsuario().getNombre() : "");
            map.put("creadorFoto", outfit.getUsuario().getFotoPerfil() != null
                ? outfit.getUsuario().getFotoPerfil() : "");
        }

        // Prendas con sus fotos
        List<Map<String, Object>> prendas = new ArrayList<>();
        for (Prenda p : outfit.getPrendas()) {
            Map<String, Object> pmap = new HashMap<>();
            pmap.put("id", p.getId());
            pmap.put("nombre", p.getNombre() != null ? p.getNombre() : "");
            pmap.put("tipo", p.getTipo() != null ? p.getTipo() : "");
            pmap.put("color", p.getColor() != null ? p.getColor() : "");
            pmap.put("fotoUrl", p.getFotoUrl() != null ? p.getFotoUrl() : "");
            prendas.add(pmap);
        }
        map.put("prendas", prendas);
        return map;
    }
}