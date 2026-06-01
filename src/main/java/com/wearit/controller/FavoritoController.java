package com.wearit.controller;

import com.wearit.model.Favorito;
import com.wearit.service.FavoritoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/favoritos")
public class FavoritoController {

    @Autowired
    private FavoritoService favoritoService;

    @GetMapping("/prendas/{usuarioId}")
    public List<Favorito> getPrendasFavoritas(@PathVariable Long usuarioId) {
        return favoritoService.getPrendasFavoritas(usuarioId);
    }

    @GetMapping("/outfits/{usuarioId}")
    public List<Favorito> getOutfitsFavoritos(@PathVariable Long usuarioId) {
        return favoritoService.getOutfitsFavoritos(usuarioId);
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