
function voltages = coeffs2voltages(pos,app)
% converts zernike coefficients to mirror voltages
% works with app if switch set to zernike polynomial position
% can be used without app if variables contained within a struct 
% (Z, influence matrix - of mirror actuators, mirror_sim)

shape = app.Z * pos;
shape = -flip(flip(shape,2),1);
voltages = (app.influence_matrix' * app.influence_matrix)^(-1) * app.influence_matrix' * shape * 4 / app.mirror_sim.volt_const;


end