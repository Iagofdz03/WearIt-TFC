package com.wearit.repository;

import com.wearit.model.Favorito;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

public interface FavoritoRepository extends JpaRepository<Favorito, Long> {
    List<Favorito> findByUsuarioIdAndPrendaIsNotNull(Long usuarioId);
    List<Favorito> findByUsuarioIdAndOutfitIsNotNull(Long usuarioId);
    boolean existsByUsuarioIdAndPrendaId(Long usuarioId, Long prendaId);
    boolean existsByUsuarioIdAndOutfitId(Long usuarioId, Long outfitId);
    @Transactional
    void deleteByUsuarioIdAndPrendaId(Long usuarioId, Long prendaId);
    @Transactional
    void deleteByUsuarioIdAndOutfitId(Long usuarioId, Long outfitId);
}