package com.wearit.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.wearit.model.HistorialOutfit;
import com.wearit.service.HistorialOutfitService;

@RestController
@RequestMapping("/api/historial")
public class HistorialOutfitController {

    @Autowired
    private HistorialOutfitService historialService;

    @GetMapping("/usuario/{usuarioId}")
    public List<HistorialOutfit> listarPorUsuario(@PathVariable Long usuarioId) {
        return historialService.listarPorUsuario(usuarioId);
    }

    @PostMapping
    public HistorialOutfit guardar(@RequestBody HistorialOutfit historial) {
        return historialService.guardar(historial);
    }

    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable Long id) {
        historialService.eliminar(id);
    }
}