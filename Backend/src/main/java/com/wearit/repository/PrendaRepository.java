package com.wearit.repository;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import com.wearit.model.Prenda;

public interface PrendaRepository extends JpaRepository<Prenda, Long> {

    List<Prenda> findByUsuarioId(Long usuarioId);

    @Query("SELECT p FROM Prenda p WHERE p.usuario.id = :usuarioId " +
           "AND (:tipo IS NULL OR p.tipo = :tipo) " +
           "AND (:nombre IS NULL OR LOWER(p.nombre) LIKE LOWER(CONCAT('%', :nombre, '%'))) " +
           "AND (:color IS NULL OR " +
           "     p.color LIKE CONCAT('%', :color, '%')) " +
           "AND (:estilo IS NULL OR " +
           "     p.estilo LIKE CONCAT('%', :estilo, '%')) " +
           "AND (:temporada IS NULL OR " +
           "     p.temporada LIKE CONCAT('%', :temporada, '%'))")
    List<Prenda> filtrar(
        @Param("usuarioId") Long usuarioId,
        @Param("tipo") String tipo,
        @Param("color") String color,
        @Param("estilo") String estilo,
        @Param("temporada") String temporada,
        @Param("nombre") String nombre
    );
}
