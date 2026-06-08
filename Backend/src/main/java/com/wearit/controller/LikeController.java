package com.wearit.controller;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import com.wearit.model.Like;
import com.wearit.service.LikeService;

@RestController
@RequestMapping("/api/likes")
public class LikeController {

    @Autowired
    private LikeService likeService;

    @GetMapping("/outfit/{outfitId}")
    public List<Like> listarPorOutfit(@PathVariable Long outfitId) {
        return likeService.listarPorOutfit(outfitId);
    }

    @GetMapping("/outfit/{outfitId}/count")
    public int contarLikes(@PathVariable Long outfitId) {
        return likeService.contarPorOutfit(outfitId);
    }

    // Flutter llama a este endpoint para saber si el usuario ya dio like
    @GetMapping("/outfit/{outfitId}/estado/{usuarioId}")
    public Map<String, Object> estadoLike(
            @PathVariable Long outfitId,
            @PathVariable Long usuarioId) {
        boolean yaDiLike = likeService.existeLike(usuarioId, outfitId);
        int count = likeService.contarPorOutfit(outfitId);
        return Map.of("yaDiLike", yaDiLike, "count", count);
    }

    @PostMapping
    public Like darLike(@RequestBody Like like) {
        return likeService.darLike(like);
    }

    @DeleteMapping("/usuario/{usuarioId}/outfit/{outfitId}")
    public void quitarLike(@PathVariable Long usuarioId, @PathVariable Long outfitId) {
        likeService.quitarLike(usuarioId, outfitId);
    }
}