# POD-Galerkin comparison protocol
Six existing sizes: 12,24,48,96,192,384; same training IDs, validation IDs 13-18 and test IDs 19-24.
No new physical samples or model seeds; original model seed 42 retained as provenance.
Mesh generated at domain midpoint with Hmax=min(b0,h0)/3, quadratic tetrahedra.
Reference coordinates [0,1]^3 mapped by diag(L,b,h), offset (-L/2,-b/2,0).
Fixed connectivity, node order and block DOF order [ux;uy;uz].
Full unconstrained K+A+Q and F+G; eliminate known zero clamp DOFs ONCE.
Uncentered nodal POD from each training subset ONLY. Ranks [1,2,4,8,11].
Choose minimum validation mean weighted relative L2 error against original FEM output fields.
Test labels/snapshots loaded only after ALL six models are frozen.
Different common mesh vs old per-case meshes: quantify discrepancy, never claim identical discretizations.
Quadratic shape-function observation on original 525-point grid; midpoint tip is on this grid.
Output projection floor is weighted least-squares projection onto O*V, NOT nodal POD coefficients.
Residual and energy errors reference the common-space full FEM; field/scalar errors reference original FEM.
Full fresh assembly is included in every ROM online timing; no affine optimization.
Original model files are read only. Re-evaluate their missing scalar outputs without retraining.
Timing repeats: three full online executions per test case; use median, store every sample.
Test set already inspected in prior series; exploratory comparison, no new blind holdout.
