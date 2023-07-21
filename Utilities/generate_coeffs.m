function coeffs = generate_coeffs(orders)
    coeffs = randn((orders*(orders+2)+orders)/2+1,1);
    coeffs = exp(-(1:length(coeffs)).^2/350)' .* coeffs/4;
end