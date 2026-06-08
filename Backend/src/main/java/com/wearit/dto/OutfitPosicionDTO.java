package com.wearit.dto;

// DTO para recibir/enviar posiciones de prendas en un outfit
public class OutfitPosicionDTO {
    private Long prendaId;
    private double x;
    private double y;
    private double scale;
    private int zIndex;
    private String removeBgUrl;

    // Getters y setters
    public Long getPrendaId() { return prendaId; }
    public void setPrendaId(Long prendaId) { this.prendaId = prendaId; }
    public double getX() { return x; }
    public void setX(double x) { this.x = x; }
    public double getY() { return y; }
    public void setY(double y) { this.y = y; }
    public double getScale() { return scale; }
    public void setScale(double scale) { this.scale = scale; }
    public int getZIndex() { return zIndex; }
    public void setZIndex(int zIndex) { this.zIndex = zIndex; }
    public String getRemoveBgUrl() { return removeBgUrl; }
    public void setRemoveBgUrl(String removeBgUrl) { this.removeBgUrl = removeBgUrl; }
}