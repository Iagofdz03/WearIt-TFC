package com.wearit.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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

    @PostMapping
    public Like darLike(@RequestBody Like like) {
        return likeService.darLike(like);
    }

    @DeleteMapping("/usuario/{usuarioId}/outfit/{outfitId}")
    public void quitarLike(@PathVariable Long usuarioId, @PathVariable Long outfitId) {
        likeService.quitarLike(usuarioId, outfitId);
    }
}