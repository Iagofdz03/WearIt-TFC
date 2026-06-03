package com.wearit.repository;

import com.wearit.model.OutfitPrendaPosicion;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

public interface OutfitPrendaPosicionRepository
        extends JpaRepository<OutfitPrendaPosicion, Long> {

	@Query("SELECT p FROM OutfitPrendaPosicion p WHERE p.outfit.id = :outfitId ORDER BY p.zIndex ASC")
	List<OutfitPrendaPosicion> findByOutfitIdOrderByZIndexAsc(@Param("outfitId") Long outfitId);

	@Transactional
	void deleteByOutfitId(Long outfitId);
}