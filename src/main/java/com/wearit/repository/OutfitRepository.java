package com.wearit.repository;

import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.wearit.model.Outfit;

public interface OutfitRepository extends JpaRepository<Outfit, Long> {
    List<Outfit> findByUsuarioId(Long usuarioId);
    
    List<Outfit> findByEsPublicoTrue();
    
    @Query("SELECT o FROM Outfit o WHERE o.esPublico = true ORDER BY (SELECT COUNT(l) FROM Like l WHERE l.outfit = o) DESC")
    List<Outfit> findOutfitsOrdenadosPorLikes();
    
    List<Outfit> findByOcasionAndEsPublicoTrue(String ocasion);
    
    @Query("SELECT o FROM Outfit o WHERE o.usuario.id = :usuarioId " +
    	       "AND (:nombre IS NULL OR LOWER(o.nombre) LIKE LOWER(CONCAT('%', :nombre, '%'))) " +
    	       "AND (:ocasion IS NULL OR o.ocasion = :ocasion) " +
    	       "AND (:esPublico IS NULL OR o.esPublico = :esPublico)")
    	List<Outfit> filtrar(@Param("usuarioId") Long usuarioId,
    	                     @Param("nombre") String nombre,
    	                     @Param("ocasion") String ocasion,
    	                     @Param("esPublico") Boolean esPublico);
    
    @Query("SELECT o FROM Outfit o WHERE o.esPublico = true " +
    	       "AND (:nombre IS NULL OR LOWER(o.nombre) LIKE LOWER(CONCAT('%', :nombre, '%'))) " +
    	       "AND (:ocasion IS NULL OR o.ocasion = :ocasion)")
    	List<Outfit> filtrarPublicos(@Param("nombre") String nombre,
    	                              @Param("ocasion") String ocasion);
    
    Page<Outfit> findByEsPublicoTrue(Pageable pageable);
}

