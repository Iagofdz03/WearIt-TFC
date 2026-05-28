package com.wearit.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.wearit.model.Prenda;

public interface PrendaRepository extends JpaRepository<Prenda, Long> {
    List<Prenda> findByUsuarioId(Long usuarioId);
}
