package com.wearit.controller;

import com.wearit.model.Favorito;
import com.wearit.model.Outfit;
import com.wearit.model.Prenda;
import com.wearit.service.FavoritoService;
import com.wearit.service.LikeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/favoritos")
public class FavoritoController {

    @Autowired private FavoritoService favoritoService;
    @Autowired private LikeService likeService;

    @GetMapping("/prendas/{usuarioId}")
    public List<Favorito> getPrendasFavoritas(@PathVariable Long usuarioId) {
        return favoritoService.getPrendasFavoritas(usuarioId);
    }

    @GetMapping("/outfits/{usuarioId}")
    public List<Map<String, Object>> getOutfitsFavoritos(@PathVariable Long usuarioId) {
        List<Favorito> favs = favoritoService.getOutfitsFavoritos(usuarioId);
        List<Map<String, Object>> resultado = new ArrayList<>();
        for (Favorito f : favs) {
            Outfit o = f.getOutfit();
            if (o == null) continue;
            Map<String, Object> map = new HashMap<>();
            map.put("id", o.getId());
            map.put("nombre", o.getNombre() != null ? o.getNombre() : "");
            map.put("ocasion", o.getOcasion() != null ? o.getOcasion() : "");
            map.put("esPublico", o.getEsPublico());
            map.put("fotoPortada", o.getFotoPortada() != null ? o.getFotoPortada() : "");
            map.put("likes", likeService.contarPorOutfit(o.getId()));
            // Prendas
            List<Map<String, Object>> prendas = new ArrayList<>();
            for (Prenda p : o.getPrendas()) {
                Map<String, Object> pm = new HashMap<>();
                pm.put("id", p.getId());
                pm.put("nombre", p.getNombre() != null ? p.getNombre() : "");
                pm.put("tipo", p.getTipo() != null ? p.getTipo() : "");
                pm.put("color", p.getColor() != null ? p.getColor() : "");
                pm.put("fotoUrl", p.getFotoUrl() != null ? p.getFotoUrl() : "");
                prendas.add(pm);
            }
            map.put("prendas", prendas);
            resultado.add(map);
        }
        return resultado;
    }

    @GetMapping("/prenda/{usuarioId}/{prendaId}")
    public Map<String, Boolean> esPrendaFavorita(
            @PathVariable Long usuarioId, @PathVariable Long prendaId) {
        return Map.of("favorito", favoritoService.esPrendaFavorita(usuarioId, prendaId));
    }

    @GetMapping("/outfit/{usuarioId}/{outfitId}")
    public Map<String, Boolean> esOutfitFavorito(
            @PathVariable Long usuarioId, @PathVariable Long outfitId) {
        return Map.of("favorito", favoritoService.esOutfitFavorito(usuarioId, outfitId));
    }

    @PostMapping("/prenda/{usuarioId}/{prendaId}")
    public void togglePrenda(
            @PathVariable Long usuarioId, @PathVariable Long prendaId) {
        favoritoService.togglePrendaFavorita(usuarioId, prendaId);
    }

    @PostMapping("/outfit/{usuarioId}/{outfitId}")
    public void toggleOutfit(
            @PathVariable Long usuarioId, @PathVariable Long outfitId) {
        favoritoService.toggleOutfitFavorito(usuarioId, outfitId);
    }
}