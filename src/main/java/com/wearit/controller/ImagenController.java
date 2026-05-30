package com.wearit.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import jakarta.servlet.http.HttpServletRequest;

import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.nio.file.*;
import java.util.Map;
import java.util.UUID;

import javax.imageio.ImageIO;

@RestController
@RequestMapping("/api/imagenes")
public class ImagenController {

	private final String uploadDir = System.getProperty("user.dir") + "/uploads/";

    @PostMapping("/subir")
    public Map<String, String> subirImagen(
            @RequestParam("file") MultipartFile file,
            HttpServletRequest request) throws IOException {

        File directory = new File(uploadDir);
        if (!directory.exists()) directory.mkdirs();

        String fileName = UUID.randomUUID() + ".png";
        file.transferTo(new File(uploadDir + fileName));

        // URL dinámica — usa el host de la petición entrante
        String baseUrl = request.getScheme() + "://" + request.getServerName()
                         + ":" + request.getServerPort();
        String url = baseUrl + "/api/imagenes/ver/" + fileName;

        return Map.of("url", url);
    }

    @GetMapping("/ver/{fileName}")
    public ResponseEntity<Resource> verImagen(@PathVariable String fileName) {
        try {
            Path filePath = Paths.get(uploadDir).resolve(fileName);
            Resource resource = new UrlResource(filePath.toUri());

            if (resource.exists() && resource.isReadable()) {
                return ResponseEntity.ok()
                    .contentType(MediaType.IMAGE_PNG)
                    .body(resource);
            }
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }
    
    @PostMapping("/remove-bg")
    public Map<String, String> removeBg(
            @RequestBody Map<String, String> body,
            HttpServletRequest request) throws IOException {  // añade HttpServletRequest
        String imageUrl = body.get("url");

        URL url = new URL(imageUrl);
        BufferedImage original = ImageIO.read(url);
        BufferedImage result = removeWhiteBackground(original);

        String fileName = UUID.randomUUID().toString() + ".png";
        ImageIO.write(result, "PNG", new File(uploadDir + fileName));

        String baseUrl = request.getScheme() + "://" + request.getServerName()
                         + ":" + request.getServerPort();
        return Map.of("url", baseUrl + "/api/imagenes/ver/" + fileName);
    }

    private BufferedImage removeWhiteBackground(BufferedImage image) {
        BufferedImage result = new BufferedImage(
            image.getWidth(), image.getHeight(), BufferedImage.TYPE_INT_ARGB);
        
        for (int y = 0; y < image.getHeight(); y++) {
            for (int x = 0; x < image.getWidth(); x++) {
                int pixel = image.getRGB(x, y);
                int r = (pixel >> 16) & 0xFF;
                int g = (pixel >> 8)  & 0xFF;
                int b =  pixel        & 0xFF;
                if (r > 200 && g > 200 && b > 200) {
                    result.setRGB(x, y, 0x00FFFFFF);
                } else {
                    result.setRGB(x, y, pixel);
                }
            }
        }
        return result;
    }
}