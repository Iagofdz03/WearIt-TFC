package com.wearit.model;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "usuario")
@Data  // Genera getters, setters, toString, equals, hashCode
@NoArgsConstructor  // Genera constructor vacío
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String nombre;

    @Column(nullable = false)
    private String contraseña;

    private String fotoPerfil;

    @Column(name = "fecha_registro")
    private LocalDateTime fechaRegistro;

    // Se ejecuta antes de guardar por primera vez
    @PrePersist
    protected void onCreate() {
        fechaRegistro = LocalDateTime.now();
    }
}
