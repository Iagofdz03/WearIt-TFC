package com.wearit.controller;

import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.beans.factory.annotation.Value;

import java.io.File;
import java.io.IOException;
import java.nio.file.*;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/imagenes")
public class ImagenController {

    private final String uploadDir = "uploads/";

    @PostMapping("/subir")
    public Map<String, String> subirImagen(@RequestParam("file") MultipartFile file) throws IOException {
        // Crear directorio si no existe
        File directory = new File(uploadDir);
        if (!directory.exists()) {
            directory.mkdirs();
        }
        
        // Guardar archivo
        String fileName = UUID.randomUUID().toString() + ".png";
        String filePath = uploadDir + fileName;
        file.transferTo(new File(filePath));
        
        // Devolver URL (usa tu IP real)
        String url = "http://172.25.20.193:8080/api/imagenes/ver/" + fileName;
        return Map.of("url", url);
    }
    
    @GetMapping("/ver/{fileName}")
    public ResponseEntity<Resource> verImagen(@PathVariable String fileName) {
        try {
            Path filePath = Paths.get(uploadDir).resolve(fileName);
            Resource resource = new UrlResource(filePath.toUri());
            
            if (resource.exists() || resource.isReadable()) {
                return ResponseEntity.ok()
                    .contentType(MediaType.IMAGE_PNG)
                    .body(resource);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }
}