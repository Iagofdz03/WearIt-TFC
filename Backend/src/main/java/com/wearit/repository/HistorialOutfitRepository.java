package com.wearit.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.wearit.model.HistorialOutfit;

import jakarta.transaction.Transactional;

public interface HistorialOutfitRepository extends JpaRepository<HistorialOutfit, Long> {
	
    List<HistorialOutfit> findByUsuarioIdOrderByFechaUsoDesc(Long usuarioId);
    
    @Transactional
    void deleteByOutfitId(Long outfitId);
}