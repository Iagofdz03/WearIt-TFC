package com.wearit.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
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
    
    @GetMapping("/usuario/{usuarioId}/exportar")
    public ResponseEntity<String> exportarCSV(@PathVariable Long usuarioId) {
        List<HistorialOutfit> historial = historialService.listarPorUsuario(usuarioId);
        
        StringBuilder csv = new StringBuilder();
        csv.append("id,outfit,ocasion,fecha_uso\n");
        
        for (HistorialOutfit h : historial) {
            csv.append(h.getId()).append(",")
               .append(h.getOutfit().getNombre()).append(",")
               .append(h.getOutfit().getOcasion()).append(",")
               .append(h.getFechaUso()).append("\n");
        }
        
        return ResponseEntity.ok()
            .header("Content-Disposition", "attachment; filename=historial.csv")
            .contentType(org.springframework.http.MediaType.parseMediaType("text/csv"))
            .body(csv.toString());
    }
}