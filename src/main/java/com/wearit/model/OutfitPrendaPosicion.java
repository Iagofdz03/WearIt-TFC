package com.wearit.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "outfit_prenda_posicion")
@Data
@NoArgsConstructor
public class OutfitPrendaPosicion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "outfit_id", nullable = false)
    private Outfit outfit;

    @ManyToOne
    @JoinColumn(name = "prenda_id", nullable = false)
    private Prenda prenda;

    private double x;
    private double y;
    private double scale;
    @Column(name = "z_index")
    private int zIndex;

    @Column(name = "remove_bg_url")
    private String removeBgUrl; // URL con fondo quitado si se aplicó
}