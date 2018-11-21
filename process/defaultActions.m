function actions = defaultActions(ex)
%defaultActions list default actions for a given experimental dataset

if strcmp(ex.sourceformat, 'VisStim')
    switch ex.ID
        case {'LatencyTest', 'LaserON', 'LaserGratings', ...
                'NaturalImages', 'NaturalVideos', 'spontanous'}
            actions = {'plotRastergram', 'plotPsth'};
        case {'RFmap', 'CatRFdetailed', 'CatRFfast', 'CatRFfast10x10'}
            actions = {'plotMap'};
        otherwise
            actions = {'plotRastergram', 'plotPsth', 'plotTuningCurve'};
    end
else
    if contains(ex.ID, 'RF')
        actions = {'plotMap'};
    else
        actions = {'plotRastergram', 'plotTuningCurve'};
    end
    if contains(ex.ID, 'Laser') || contains(ex.ID, 'Flash')
        actions = [actions, {'plotPsth'}];
    end
    if contains(ex.ID, 'Laser')
        actions = [actions, {'plotLfp'}];
    end
    if strcmp(ex.ID, 'Image') || strcmp(ex.ID, 'LaserImage')
        actions = {'skip'};
    end
end

end