package com.wearit.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.wearit.model.Like;

public interface LikeRepository extends JpaRepository<Like, Long> {
    List<Like> findByOutfitId(Long outfitId);
    boolean existsByUsuarioIdAndOutfitId(Long usuarioId, Long outfitId);
    void deleteByUsuarioIdAndOutfitId(Long usuarioId, Long outfitId);
}