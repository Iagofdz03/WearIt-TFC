package com.wearit.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.wearit.dto.SugerenciaOutfitDTO;
import com.wearit.model.Outfit;
import com.wearit.service.OutfitService;
import com.wearit.service.OutfitSugerenciaService;

@RestController
@RequestMapping("/api/outfits")
public class OutfitController {

    @Autowired
    private OutfitService outfitService;

    @GetMapping
    public List<Outfit> listar() {
        return outfitService.listarTodos();
    }

    @GetMapping("/usuario/{usuarioId}")
    public List<Outfit> listarPorUsuario(@PathVariable Long usuarioId) {
        return outfitService.listarPorUsuario(usuarioId);
    }

    @GetMapping("/publicos")
    public List<Outfit> listarPublicos() {
        return outfitService.listarPublicos();
    }

    @GetMapping("/{id}")
    public Outfit buscarPorId(@PathVariable Long id) {
        return outfitService.buscarPorId(id);
    }

    @PostMapping
    public Outfit crear(@RequestBody Outfit outfit) {
        return outfitService.crear(outfit);
    }

    @PutMapping("/{id}")
    public Outfit actualizar(@PathVariable Long id, @RequestBody Outfit datos) {
        return outfitService.actualizar(id, datos);
    }

    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable Long id) {
        outfitService.eliminar(id);
    }
    
    @Autowired
    private OutfitSugerenciaService sugerenciaService;

    @GetMapping("/sugerir/{usuarioId}")
    public List<SugerenciaOutfitDTO> sugerirOutfits(@PathVariable Long usuarioId) {
        return sugerenciaService.sugerirOutfits(usuarioId);
    }
}
