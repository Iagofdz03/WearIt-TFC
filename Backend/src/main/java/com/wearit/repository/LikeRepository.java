package com.wearit.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.wearit.model.Like;

import jakarta.transaction.Transactional;

public interface LikeRepository extends JpaRepository<Like, Long> {

    List<Like> findByOutfitId(Long outfitId);

    boolean existsByUsuarioIdAndOutfitId(Long usuarioId, Long outfitId);

    void deleteByUsuarioIdAndOutfitId(Long usuarioId, Long outfitId);

    // Cuenta likes de un outfit concreto
    long countByOutfitId(Long outfitId);

    // Devuelve los IDs de outfits públicos ordenados por likes — una sola query
    @Query("SELECT l.outfit.id, COUNT(l) as total FROM Like l " +
           "WHERE l.outfit.esPublico = true " +
           "GROUP BY l.outfit.id " +
           "ORDER BY total DESC")
    List<Object[]> findOutfitIdsByLikesDesc();
    
    @Transactional
    void deleteByOutfitId(Long outfitId);
}