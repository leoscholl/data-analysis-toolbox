function [Y, f] = spectrum(lfp, fs)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

L = size(lfp, 1);
T = L/fs;
Y = abs(fft(lfp))/L;
Y = Y(1:floor(size(Y,1)/2),:);

f = fs/2*linspace(0,1,floor(T*fs/2));

