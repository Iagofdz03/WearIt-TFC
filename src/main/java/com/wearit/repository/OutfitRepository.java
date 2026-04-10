package com.wearit.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.wearit.model.Outfit;

public interface OutfitRepository extends JpaRepository<Outfit, Long> {
    List<Outfit> findByUsuarioId(Long usuarioId);
    List<Outfit> findByEsPublicoTrue();  // Para el feed social
}