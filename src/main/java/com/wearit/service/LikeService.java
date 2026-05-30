package com.wearit.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.wearit.model.Like;
import com.wearit.repository.LikeRepository;

@Service
public class LikeService {

    @Autowired
    private LikeRepository likeRepository;

    public List<Like> listarPorOutfit(Long outfitId) {
        return likeRepository.findByOutfitId(outfitId);
    }

    // Usa countByOutfitId — más eficiente que .size()
    public int contarPorOutfit(Long outfitId) {
        return (int) likeRepository.countByOutfitId(outfitId);
    }

    public boolean existeLike(Long usuarioId, Long outfitId) {
        return likeRepository.existsByUsuarioIdAndOutfitId(usuarioId, outfitId);
    }

    public Like darLike(Like like) {
        boolean yaExiste = likeRepository.existsByUsuarioIdAndOutfitId(
            like.getUsuario().getId(), like.getOutfit().getId()
        );
        if (yaExiste) {
            throw new RuntimeException("Ya has dado like a este outfit");
        }
        return likeRepository.save(like);
    }

    @Transactional
    public void quitarLike(Long usuarioId, Long outfitId) {
        likeRepository.deleteByUsuarioIdAndOutfitId(usuarioId, outfitId);
    }

    // Devuelve IDs ordenados por likes en una sola query
    public List<Object[]> getRankingIds() {
        return likeRepository.findOutfitIdsByLikesDesc();
    }
}