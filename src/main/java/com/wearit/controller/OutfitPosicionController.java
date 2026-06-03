package com.wearit.controller;

import com.wearit.dto.OutfitPosicionDTO;
import com.wearit.model.Outfit;
import com.wearit.model.OutfitPrendaPosicion;
import com.wearit.model.Prenda;
import com.wearit.repository.OutfitPrendaPosicionRepository;
import com.wearit.repository.OutfitRepository;
import com.wearit.repository.PrendaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.HashMap;

@RestController
@RequestMapping("/api/outfits/{outfitId}/posiciones")
public class OutfitPosicionController {

    @Autowired private OutfitPrendaPosicionRepository posicionRepo;
    @Autowired private OutfitRepository outfitRepo;
    @Autowired private PrendaRepository prendaRepo;

    // Obtener posiciones de un outfit
    @GetMapping
    public List<Map<String, Object>> getPosiciones(@PathVariable Long outfitId) {
        return posicionRepo.findByOutfitIdOrderByZIndexAsc(outfitId)
            .stream()
            .map(p -> {
                Map<String, Object> map = new HashMap<>();
                map.put("prendaId", p.getPrenda().getId());
                map.put("nombre",   p.getPrenda().getNombre() != null ? p.getPrenda().getNombre() : "");
                map.put("tipo",     p.getPrenda().getTipo() != null ? p.getPrenda().getTipo() : "");
                map.put("color",    p.getPrenda().getColor() != null ? p.getPrenda().getColor() : "");
                map.put("fotoUrl",  p.getRemoveBgUrl() != null && !p.getRemoveBgUrl().isEmpty()
                                        ? p.getRemoveBgUrl()
                                        : (p.getPrenda().getFotoUrl() != null ? p.getPrenda().getFotoUrl() : ""));
                map.put("x",        p.getX());
                map.put("y",        p.getY());
                map.put("scale",    p.getScale());
                map.put("zIndex",   p.getZIndex());
                return map;
            })
            .collect(Collectors.toList());
    }

    // Guardar/actualizar posiciones (reemplaza las anteriores)
    @PostMapping
    @Transactional
    public void guardarPosiciones(
            @PathVariable Long outfitId,
            @RequestBody List<OutfitPosicionDTO> posiciones) {

        Outfit outfit = outfitRepo.findById(outfitId)
            .orElseThrow(() -> new RuntimeException("Outfit no encontrado"));

        // Borra las posiciones anteriores
        posicionRepo.deleteByOutfitId(outfitId);

        // Guarda las nuevas
        for (int i = 0; i < posiciones.size(); i++) {
            OutfitPosicionDTO dto = posiciones.get(i);
            Prenda prenda = prendaRepo.findById(dto.getPrendaId())
                .orElseThrow(() -> new RuntimeException("Prenda no encontrada"));

            OutfitPrendaPosicion pos = new OutfitPrendaPosicion();
            pos.setOutfit(outfit);
            pos.setPrenda(prenda);
            pos.setX(dto.getX());
            pos.setY(dto.getY());
            pos.setScale(dto.getScale());
            pos.setZIndex(dto.getZIndex() > 0 ? dto.getZIndex() : i);
            pos.setRemoveBgUrl(dto.getRemoveBgUrl());
            posicionRepo.save(pos);
        }
    }
}