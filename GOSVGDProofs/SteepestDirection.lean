import Mathlib.Data.Real.EReal
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Integral.Bochner
import Mathlib.Analysis.Calculus.FDeriv.Basic

import GOSVGDProofs.PushForward

local macro_rules | `($x ^ $y) => `(HPow.hPow $x $y)

open scoped RealInnerProductSpace 
open BigOperators Finset ENNReal NNReal MeasureTheory MeasureTheory.Measure IsROrC

set_option trace.Meta.Tactic.simp.rewrite true
set_option maxHeartbeats 4000000

/-
  We defined measures μ and π (ν is considered as the standard Lebesgue measure) along with their densities (finite and non-zero on the entire space)
-/
variable {d : ℕ}

variable [MeasurableSpace (Vector ℝ d)] [MeasureSpace (Vector ℝ d)] [MeasureSpace ℝ]

variable (μ π ν : Measure (Vector ℝ d)) (dμ dπ : (Vector ℝ d) → ℝ≥0∞) (hμ : is_density μ ν dμ) (hπ : is_density π ν dπ) (mdμ : Measurable dμ) (mdπ : Measurable dπ) (hdμ : ∀x, dμ x ≠ 0 ∧ dμ x ≠ ∞) (hdπ : ∀x, dπ x ≠ 0 ∧ dπ x ≠ ∞)

variable [IsProbabilityMeasure μ] [IsProbabilityMeasure π]

variable (h_m_set : ∀ (s : Set (Vector ℝ d)), MeasurableSet s)

/-=====================================RKHS SECTION=====================================-/

/-
  Here we define the product RKHS and we prove that H ⊆ L²(μ)
-/

/-
  We define a RKHS of ((Vector ℝ d) → ℝ) functions.
-/
variable (H₀ : Set ((Vector ℝ d) → ℝ)) [NormedAddCommGroup ((Vector ℝ d) → ℝ)] [InnerProductSpace ℝ ((Vector ℝ d) → ℝ)]

/- The kernel function -/
variable (k : (Vector ℝ d) → (Vector ℝ d) → ℝ) (h_k : (∀ (x : (Vector ℝ d)), k x ∈ H₀) ∧ (∀ (x : (Vector ℝ d)), (fun y ↦ k y x) ∈ H₀))

/--
  Reproducing propriety
-/
def is_kernel := ∀ (f : (Vector ℝ d) → ℝ), f ∈ H₀ → ∀ (x : (Vector ℝ d)), f x = ⟪f, k x⟫

/--
  Positive definite kernel
-/
def positive_definite_kernel := ∀ (f : ℕ → Vector ℝ d → ℝ), (0 ≤ ∫ x in Set.univ, (∫ x' in Set.univ, (∑ i in range (d + 1), f i x * k x x' * f i x') ∂μ) ∂μ) ∧ (∫ x in Set.univ, (∫ x' in Set.univ, (∑ i in range (d + 1), f i x * k x x' * f i x') ∂μ) ∂μ = 0 ↔ ∀x, ∀i, f i x = 0)

variable (h_kernel : is_kernel H₀ k) (h_kernel_positive : positive_definite_kernel μ k)

/- We define the product RKHS as a space of function on (ℕ → (Vector ℝ d) → ℝ). A function belongs to such a RKHS if f = (f_1, ..., f_d) and ∀ 1 ≤ i ≤ d, fᵢ ∈ H₀. -/
variable {H : Set (ℕ → (Vector ℝ d) → ℝ)} [NormedAddCommGroup (ℕ → (Vector ℝ d) → ℝ)] [InnerProductSpace ℝ (ℕ → (Vector ℝ d) → ℝ)]

def product_RKHS (H : Set (ℕ → (Vector ℝ d) → ℝ)) (H₀ : Set ((Vector ℝ d) → ℝ)) := ∀ f ∈ H, ∀ (i : ℕ), i ∈ range (d + 1) → f i ∈ H₀

def inner_product_H (H : Set (ℕ → (Vector ℝ d) → ℝ)) := ∀ f ∈ H, ∀ g ∈ H, ⟪f, g⟫ = ∑ i in range (d + 1), ⟪f i, g i⟫

variable [NormedAddCommGroup (ℕ → ℝ)] [InnerProductSpace ℝ (ℕ → ℝ)] [CompleteSpace (ℕ → ℝ)]
/--
  The simple vector norm
-/
def norm_H (H : Set (ℕ → (Vector ℝ d) → ℝ)) := ∀ f ∈ H, ∀x, (‖fun i ↦ f i x‖₊ : ℝ≥0∞) = sqrt (∑ i in range (d + 1), ‖f i x‖₊^2)

/--
  For all non-empty finite set s, ∃ e ∈ s, ∀ a ∈ s, a ≤ e.
-/
lemma exist_max_finset {ι : Type _} [LinearOrder ι] (s : Finset ι) (h : Finset.Nonempty s) : ∃ e ∈ s, ∀ a ∈ s, a ≤ e :=
by
  use (Finset.max' s h)
  constructor
  {exact max'_mem s h}
  {
    intros a ains
    exact le_max' s a ains
  }

/--
  Given a non-empty finite set s and a function f on elements of s, ∃ j ∈ s, ∀ i ∈ s, f i ≤ f j.
-/
lemma exist_max_image_finset {ι E : Type _} [LinearOrder E] (s : Finset ι) (h : Finset.Nonempty s) (f : ι → E) : ∃ j ∈ s, ∀ i ∈ s, f i ≤ f j :=
by 
  let sf := Finset.image f s
  have hf : Finset.Nonempty sf := Nonempty.image h f

  have max : ∃ e ∈ sf, ∀ a ∈ sf, a ≤ e := exist_max_finset sf hf

  rcases max with ⟨c, cin, max⟩
  rw [Finset.mem_image] at cin
  rcases cin with ⟨j, jin, fj⟩

  use j
  constructor
  {exact jin}
  intros i iin
  specialize max (f i)
  rw [fj]
  exact max (mem_image_of_mem f iin)

/--
  a*a = a²
-/
lemma square {M : Type _} [Monoid M] (a : M) : a * a = a^2 := (sq a).symm

/--
  a² * b² = (a * b)²
-/
lemma distrib_sq {M : Type _} [CommMonoid M] (a b : M) : a^2 * b^2 = (a * b)^2 := (mul_pow a b 2).symm
/--
  ∀ a b ∈ ℝ⁺ ∪ {∞}, a ≤ b → a² ≤ b²
-/
lemma le_square {a b : ℝ≥0∞} (h : a ≤ b) : a^2 ≤ b^2 :=
by
  have k := mul_le_mul h h (by simp) (by simp)
  rwa [←square a, ←square b]

/- Coercion lemmas -/

lemma le_coe (a : ℝ) (b : NNReal) (h1 : 0 ≤ a) : ‖a‖₊ ≤ b → ENNReal.ofReal a ≤ ENNReal.ofReal b :=
by
  intro h
  have k := Real.ennnorm_eq_ofReal h1
  rw [←k]
  rwa [ENNReal.ofReal_coe_nnreal, ENNReal.coe_le_coe]

lemma coe_nnreal_le {a b : ℝ≥0} (h : a ≤ b) : (a : ℝ≥0∞) ≤ (b : ℝ≥0∞) := Iff.mpr coe_le_coe h

lemma coe_distrib (a b : ℝ≥0) : ENNReal.some (a * b) = (a : ℝ≥0∞) * (b : ℝ≥0∞) := ENNReal.coe_mul

lemma nn_norm_eq_norm (a : (Vector ℝ d) → ℝ) : ‖a‖₊ = ENNReal.ofReal ‖a‖ := (ofReal_norm_eq_coe_nnnorm a).symm

lemma nn_norm_eq_norm_re (a : ℝ) : ‖a‖₊ = ENNReal.ofReal ‖a‖ := (ofReal_norm_eq_coe_nnnorm a).symm

lemma enn_square {a : ℝ} (h : 0 ≤ a) : ENNReal.ofReal (a) ^ 2 = ENNReal.ofReal (a ^ 2) :=
by
  rw [←square (ENNReal.ofReal (a)), ←square a]
  exact (ofReal_mul h).symm

lemma nn_square {a : ℝ≥0} : (a : ℝ≥0∞) ^ 2 = (a ^ 2 : ℝ≥0∞) := (ENNReal.coe_pow 2).symm

/--
  A finite sum of finite elements is finite.
-/
lemma finite_sum (f : ℕ → ℝ≥0) : ∃ (C : ℝ≥0), ∑ i in range (d + 1), (f i : ℝ≥0∞) < ENNReal.some C :=
by
  /- We begin to show that each element of the sum is bounded from above. -/
  have sup_el : ∀ i ∈ range (d + 1), ∃ c, (f i) < c := fun i _ ↦ exists_gt (f i)

  /- We find the argmax of the set {f i | ∀ i ∈ range (d + 1)} using the *exist_max_image_finset* lemma. -/
  have max : ∃ j ∈ range (d+1), ∀ i ∈ range (d+1), f i ≤ f j := by {
    have non_empty : ∀ (n : ℕ), Finset.Nonempty (range (n+1)) := fun n ↦ nonempty_range_succ
    have max := exist_max_image_finset (range (d+1)) (non_empty d) (fun i ↦ f i)
    rcases max with ⟨j, jin, max⟩
    use j
  }

  /- We show that the majorant of the biggest element majors every element of the sum  -/
  have sup : ∃ c, ∀ i ∈ range (d + 1), f i < c := by {
    rcases max with ⟨j, jin, max⟩
    choose C sup_el using sup_el
    use (C j jin)
    intros i iin
    specialize max i iin
    specialize sup_el j jin
    calc (f i) ≤ (f j) := max
    _ < C j jin := sup_el
  }

  /- Same as above, with coercion -/
  have sup_coe : ∃ (c:ℝ≥0), ∀ (i : ℕ), i ∈ range (d + 1) → (f i : ℝ≥0∞) < c := by {
    rcases sup with ⟨C, sup⟩
    use C
    intros i iin
    specialize sup i iin
    have coe_lt : ∀ (a b : ℝ≥0), (a < b) → ENNReal.some a < ENNReal.some b := by {
      intros a b h
      exact Iff.mpr coe_lt_coe h
    }
    exact coe_lt (f i) C sup
  }

  rcases sup_coe with ⟨c, sup_coe⟩

  /- The sum is bounded from above by the sum of the majorant -/
  have sum_le : ∑ i in range (d + 1), (f i : ℝ≥0∞) < ∑ i in range (d + 1), (c : ℝ≥0∞) := sum_lt_sum_of_nonempty (by simp) sup_coe

  /- Same as above, with coercion -/
  have sum_coe : ∑ i in range (d + 1), (c : ℝ≥0∞) = ENNReal.some (∑ i in range (d + 1), c) := coe_finset_sum.symm

  /- Sum of constant = constant -/
  have sum_simpl : ∑ i in range (d + 1), c = (d+1) • c := (nsmul_eq_sum_const c (d + 1)).symm

  use ((d+1) • c)

  calc ∑ i in range (d + 1), (f i: ℝ≥0∞) < ∑ i in range (d + 1), (c : ℝ≥0∞) := sum_le
  _ = ENNReal.some (∑ i in range (d + 1), c) := sum_coe
  _ = ENNReal.some ((d+1) • c) := by rw [sum_simpl]

def integral_is_finite (μ : Measure (Vector ℝ d)) (f : (Vector ℝ d) → ℝ) := ∃ (C : ℝ≥0), ∫⁻ x in Set.univ, ENNReal.ofReal |f x| ∂μ < C

/--
  H ⊆ L2(μ) i.e., ∀ f ∈ H ∫⁻ x in Set.univ, ∑ i in range (d + 1), ENNReal.ofReal (|f i x|)^2 ∂μ < ∞.
-/
example (f : ℕ → (Vector ℝ d) → ℝ) (x : (Vector ℝ d)) : ENNReal.ofReal ‖fun i ↦ f i x‖ = ‖fun i ↦ f i x‖₊ := ofReal_norm_eq_coe_nnnorm fun i => f i x

theorem H_subset_of_L2 (μ : Measure (Vector ℝ d)) (h1 : product_RKHS H H₀) (h2 : integral_is_finite μ (fun x ↦ k x x)) (h3 : norm_H H) : ∀ f ∈ H, ∫⁻ x in Set.univ, ENNReal.ofReal ‖fun i ↦ f i x‖^2 ∂μ < ∞ :=
by
  intros f finH

  /- We rewrite the absolute value of a norm as positive norm. -/
  have abs_to_nnorm : ∀ x, ENNReal.ofReal ‖fun i ↦ f i x‖ = ‖fun i ↦ f i x‖₊ := fun x ↦ ofReal_norm_eq_coe_nnnorm fun i => f i x
  simp_rw [abs_to_nnorm]

  /- We use the property of H to rewrite the norm as a sum of norm of function in H₀ -/
  have H_norm : ∀ x, (‖fun i ↦ f i x‖₊ : ℝ≥0∞)^2 = ∑ i in range (d + 1), (‖f i x‖₊ : ℝ≥0∞)^2 := by {
    intro x
    rw [h3 f finH x]
    have sq_coe : ENNReal.some (sqrt (∑ i in range (d + 1), ‖f i x‖₊ ^ 2))^2 = ENNReal.some ((sqrt (∑ i in range (d + 1), ‖f i x‖₊ ^ 2))^2) := nn_square
    rw [sq_coe]
    simp
  }
  simp_rw [H_norm]

  /- We use the reproducing propriety of H₀ to rewrite f i x as ⟪f i, k x⟫. -/
  have rkhs : ∀ (x : (Vector ℝ d)), ∑ i in range (d + 1), (‖f i x‖₊ : ℝ≥0∞)^2 = ∑ i in range (d + 1), (‖⟪f i, k x⟫‖₊ : ℝ≥0∞)^2 := by {
    have temp : ∀ (x : (Vector ℝ d)), ∀ (i : ℕ), i ∈ range (d + 1) → f i x = ⟪f i, k x⟫ := by
    {
      intros x i iInRange
      apply h_kernel
      exact h1 f finH i iInRange
    }
    intro x
    apply sum_congr (Eq.refl _)
    intros i iInRange
    rw [temp x i iInRange]
  }
  simp_rw [rkhs]

  /- Coersive Cauchy-Schwarz inequality : ↑‖⟪f i, k x⟫‖₊ ≤ ↑‖f i‖₊ ↑‖f x‖₊. -/
  have cauchy_schwarz : ∀x, ∀i ∈ range (d + 1), (‖⟪f i, k x⟫‖₊ : ℝ≥0∞) ≤ (‖f i‖₊ : ℝ≥0∞) * (‖k x‖₊ : ℝ≥0∞) := by {
    intros x i _iInRange
    have nn_cauchy := nnnorm_inner_le_nnnorm (𝕜 := ℝ) (f i) (k x)
    have distrib : ENNReal.some (‖f i‖₊ * ‖k x‖₊) = (‖f i‖₊ : ℝ≥0∞) * (‖k x‖₊ : ℝ≥0∞) := coe_distrib ‖f i‖₊ ‖k x‖₊
    rw [←distrib]
    exact coe_nnreal_le nn_cauchy
  }

  /- Coersive "square" Cauchy-Schwarz inequality : (↑‖⟪f i, k x⟫‖₊)² ≤ (↑‖f i‖₊)² (↑‖f x‖₊)². -/
  have cauchy_schwarz_sq : ∀x, ∀i ∈ range (d + 1), (‖⟪f i, k x⟫‖₊ : ℝ≥0∞)^2 ≤ (‖f i‖₊ : ℝ≥0∞)^2 * (‖k x‖₊ : ℝ≥0∞)^2 := by {
    intros x i iInRange
    have sq_dist : ((‖f i‖₊ : ℝ≥0∞) * (‖k x‖₊ : ℝ≥0∞))^2 = (‖f i‖₊ : ℝ≥0∞)^2 * (‖k x‖₊ : ℝ≥0∞)^2 := (distrib_sq (‖f i‖₊ : ℝ≥0∞) (‖k x‖₊ : ℝ≥0∞)).symm
    rw [←sq_dist]
    exact le_square (cauchy_schwarz x i iInRange)
  }

  /- If f ≤ g, ∑ i in s, f ≤ ∑ i in s, g. Thus, ∑ i in range (d + 1), (↑‖⟪f i, k x⟫‖₊)² ≤ ∑ i in range (d + 1), (↑‖f i‖)² * (↑‖k x‖₊)². -/
  have sum_le : (fun x ↦ ∑ i in range (d + 1), (‖⟪f i, k x⟫‖₊ : ℝ≥0∞)^2) ≤ (fun x ↦ ∑ i in range (d + 1), (‖f i‖₊ : ℝ≥0∞)^2 * (‖k x‖₊ : ℝ≥0∞)^2) := fun x ↦ sum_le_sum (cauchy_schwarz_sq x)

  /- A lower-Lebesgue integral of a finite sum is equal to a finite sum of lower-Lebesgue integral. -/
  have inverse_sum_int : ∫⁻ x in Set.univ, ∑ i in range (d + 1), (‖f i‖₊ : ℝ≥0∞)^2 * (‖k x‖₊ : ℝ≥0∞)^2 ∂μ = ∑ i in range (d + 1), ∫⁻ x in Set.univ, (‖f i‖₊ : ℝ≥0∞)^2 * (‖k x‖₊ : ℝ≥0∞)^2 ∂μ := by {
    have is_measurable : ∀ i ∈ range (d + 1), Measurable ((fun i ↦ fun x ↦ (‖f i‖₊ : ℝ≥0∞)^2 * (‖k x‖₊ : ℝ≥0∞)^2) i) := by
    {
      intros i _InRange s _h
      exact h_m_set _
    }
    exact lintegral_finset_sum (range (d + 1)) is_measurable
  }

  /- Retrieve the majorant of the finite sum : ∑ i in range (d + 1), (↑‖f i‖₊)². -/
  rcases finite_sum (fun i ↦ ‖f i‖₊^2) with ⟨C1, finite_sum⟩

  /- Retrieve the majorant of the integral ∫⁻ (x : (Vector ℝ d)) in Set.univ, ↑|k x x| ∂μ, supposed finite. -/
  rcases h2 with ⟨C2, h2⟩
  /- Rewrite ↑|k x x| as  ↑‖k x x‖₊. -/
  have abs_to_nnorm : ∀ x, ENNReal.ofReal (|k x x|) = ‖k x x‖₊ := fun x ↦ (Real.ennnorm_eq_ofReal_abs (k x x)).symm
  simp_rw [abs_to_nnorm] at h2

  /- 1. ∀ f ≤ g, ∫⁻ x, f x ∂μ ≤ ∫⁻ x, g x ∂μ. We use this lemma with *sum_le*. -/
  calc ∫⁻ (x : (Vector ℝ d)) in Set.univ, ∑ i in range (d + 1), (‖⟪f i, k x⟫‖₊ : ℝ≥0∞)^2 ∂μ ≤ ∫⁻ (x : (Vector ℝ d)) in Set.univ, ∑ i in range (d + 1), (‖f i‖₊ : ℝ≥0∞)^2 * (‖k x‖₊ : ℝ≥0∞)^2 ∂μ := lintegral_mono sum_le

  /- 2. Inversion sum integral. -/
  _ = ∑ i in range (d + 1), ∫⁻ (x : (Vector ℝ d)) in Set.univ, (‖f i‖₊ : ℝ≥0∞)^2 * (‖k x‖₊ : ℝ≥0∞)^2 ∂μ := inverse_sum_int

  /- 3. As (↑‖f i‖₊)² is a constant in the integral, get it out. -/
  _ = ∑ i in range (d + 1), (‖f i‖₊ : ℝ≥0∞)^2 * ∫⁻ (x : (Vector ℝ d)) in Set.univ, (‖k x‖₊ : ℝ≥0∞)^2 ∂μ := by {
    have is_measurable : Measurable (fun x ↦ (‖k x‖₊ : ℝ≥0∞)^2) := by {
      intros s _hs
      exact h_m_set _
    }
    have const_int : ∀ i, ∫⁻ (x : (Vector ℝ d)) in Set.univ, (‖f i‖₊ : ℝ≥0∞)^2 * (‖k x‖₊ : ℝ≥0∞)^2 ∂μ = (‖f i‖₊ : ℝ≥0∞)^2 * ∫⁻ (x : (Vector ℝ d)) in Set.univ, (‖k x‖₊ : ℝ≥0∞)^2 ∂μ := by {
      intro i
      exact lintegral_const_mul ((‖f i‖₊ : ℝ≥0∞)^2) is_measurable
    }
    simp_rw [const_int]
  }

  /- Rewrite  (↑‖k x‖₊)² as ↑‖⟪k x, k x⟫‖₊ (lot of coercions). -/
  _ = ∑ i in range (d + 1), (‖f i‖₊ : ℝ≥0∞)^2 * ∫⁻ (x : (Vector ℝ d)) in Set.univ, (‖⟪k x, k x⟫‖₊ : ℝ≥0∞) ∂μ := by {
    
    simp_rw [fun x ↦ nn_norm_eq_norm (k x)]

    simp_rw [fun x ↦ enn_square (norm_nonneg (k x))]

    have norm_sq_eq_inner : ∀ x, ⟪k x, k x⟫ = ‖k x‖ ^ 2 := by {
      intro x
      have tt := inner_self_eq_norm_sq_to_K (𝕜 := ℝ) (k x)
      rw [tt]
      simp
    }
    simp_rw [norm_sq_eq_inner]

    have coe : ∀x, ENNReal.ofReal (‖k x‖ ^ 2) = ↑‖‖k x‖ ^ 2‖₊ := by {
      intro x
      rw [nn_norm_eq_norm_re (‖k x‖ ^ 2)]
      simp
    }
    simp_rw [coe]
  }
  
  /- Use the reproducing propriety of H₀ to write ⟪k x, k x⟫ as k x x. -/
  _ = ∑ i in range (d + 1), (‖f i‖₊ : ℝ≥0∞)^2 * ∫⁻ (x : (Vector ℝ d)) in Set.univ, (‖k x x‖₊ : ℝ≥0∞) ∂μ := by {
    have reproducing_prop : ∀ x, ⟪k x, k x⟫ = k x x := by {
    intro x
    rw [h_kernel (k x) (h_k.left x) x]
    }
    simp_rw [reproducing_prop]
  }

  /- As the integral is a constant in the sum, write ∑ i in ... * ∫⁻ ... as (∑ i in ...) * ∫⁻ ... -/
  _ = (∑ i in range (d + 1), (‖f i‖₊ : ℝ≥0∞)^2) * ∫⁻ (x : (Vector ℝ d)) in Set.univ, (‖k x x‖₊ : ℝ≥0∞) ∂μ := by {
    have sum_mul : (∑ i in range (d + 1), (‖f i‖₊ : ℝ≥0∞)^2) * (∫⁻ (x : (Vector ℝ d)) in Set.univ, (‖k x x‖₊ : ℝ≥0∞) ∂μ) = ∑ i in range (d + 1), (‖f i‖₊ : ℝ≥0∞)^2 * (∫⁻ (x : (Vector ℝ d)) in Set.univ, (‖k x x‖₊ : ℝ≥0∞) ∂μ) := by exact sum_mul
    rw [←sum_mul]
  }

  /- Rewrite (↑‖f i‖₊)² as ↑(‖f i‖₊²) to use the *finite_sum* lemma. -/
  _ = (∑ i in range (d + 1), (‖f i‖₊^2 : ℝ≥0∞)) * ∫⁻ (x : (Vector ℝ d)) in Set.univ, (‖k x x‖₊ : ℝ≥0∞) ∂μ := by {
    have coe_sq : ∀ i, (‖f i‖₊ : ℝ≥0∞)^2 = (‖f i‖₊^2 : ℝ≥0∞) := fun i ↦ nn_square
    simp_rw [coe_sq]
  }

  /- Bound the product from above using the two previously retrieved majorants. -/
  _ < C1 * C2 := ENNReal.mul_lt_mul finite_sum h2

  /- C1 C2 ∈ ℝ≥0 -/
  _ < ∞ := by {
    have h1 : C1 < ∞ := ENNReal.coe_lt_top
    have h2 : C2 < ∞ := ENNReal.coe_lt_top
    exact ENNReal.mul_lt_mul h1 h2
  }

/-==============================STEEPEST DIRECTION SECTION==============================-/

/-
  We prove that x ↦ ϕ i x / ‖ϕ‖ is the steepest direction to update the distribution for minimizing the KL derivative.
-/

/-
  From here, as the derivative of multivariate function are hard to define and to manipulate (defining the gradient, the divergence...), we define the gradient of *f* as follows:
  f  : Vector ℝ d → ℝ
  df : ℕ → Vector ℝ d → ℝ
       i ↦ x ↦ ∂xⁱ f(x)
  
  For vector-valued function, we defined them as follows:
  f  : ℕ → Vector ℝ d → ℝ
       i ↦ x ↦ f(x)ⁱ
  df : ℕ → Vector ℝ d → ℝ
       i ↦ x ↦ ∂xⁱ f(x)ⁱ

  Also, we assume some simple lemmas using the above formalism. Sometimes, these lemmas are not rigorously defined but, in our framework, it is more than enough. 
-/

/- dk : x ↦ i ↦ y ↦ ∂xⁱ k(x, y) -/
variable (dk : (Vector ℝ d) → ℕ → (Vector ℝ d) → ℝ)

/-ASSUMED LEMMAS-/
/--
  Linearity of inner product applied to integral
-/
lemma inter_inner_integral_right (μ : Measure (Vector ℝ d)) (g : (Vector ℝ d) → ℝ) (f : (Vector ℝ d) → (Vector ℝ d) → ℝ) : ⟪g, (fun x ↦ (∫ y, f y x ∂μ))⟫ = ∫ y, ⟪g, f y⟫ ∂μ :=
by
sorry

/--
  Linearity of inner product for function
-/
lemma inner_linear_left (f a b : Vector ℝ d → ℝ) (c : ℝ) : ⟪f, fun x ↦ c * a x + b x⟫ = c * ⟪f, fun x ↦ a x⟫ + ⟪f, fun x ↦ b x⟫ := by sorry

/--
⟪f, ∇k(x, ̇)⟫ = ∇f(x)
-/
theorem reproducing_derivative (f : (Vector ℝ d) → ℝ) (df' : ℕ → (Vector ℝ d) → ℝ) (hf : f ∈ H₀) : ∀x, ∀ i ∈ range (d + 1), ⟪f, dk x i⟫ = df' i x :=
by
  -- See Theorem 1 of *Derivative reproducing properties for kernel methods in learning theory*
  sorry

/--
  Linearity of inner product for function
-/
lemma inner_linear_right (f a b : ℕ → Vector ℝ d → ℝ) (c : ℝ) : ⟪fun i x ↦ c * a i x + b i x, f⟫ = c * ⟪fun i x ↦ a i x, f⟫ + ⟪fun i x ↦ b i x, f⟫ := by sorry

lemma inner_zero (a : ℕ → Vector ℝ d → ℝ) : ⟪0, a⟫ = 0 := by sorry

/-==============-/

/- d_log_π : i ↦ x ↦ ∂xⁱ log (μ(x) / π(x)) -/
variable (d_log_π : ℕ → (Vector ℝ d) → ℝ)

/- Definition of the steepest direction ϕ -/
variable (ϕ : ℕ → (Vector ℝ d) → ℝ) (hϕ : ϕ ∈ H) (dϕ : ℕ → (Vector ℝ d) → ℝ) 

def is_phi (ϕ : ℕ → (Vector ℝ d) → ℝ) := ∀ i, ϕ i = (fun x ↦ ∫ y, (d_log_π i y) * (k y x) + (dk y i x) ∂μ)

variable (h_is_ϕ : is_phi μ k dk d_log_π ϕ)

/- We allow ourselve to assume that for easier writing. We will use this only when f is trivially finite (e.g. product of finite functions) and well-defined. -/
variable (is_integrable_H : ∀ (f : ℕ → Vector ℝ d → ℝ), ∀ i ∈ range (d + 1), Integrable (f i) μ)

/--
We show that ⟪f, ϕ⟫ = 𝔼 x ∼ μ [∑ l in range (d + 1), ((d_log_π l x) * (f l x) + df l x)], where ϕ i x = ∫ y, (d_log_π i y) * (k y x) + (dk y i x) ∂μ.
-/
lemma inner_product_eq_dKL (h1 : product_RKHS H H₀) (h2 : inner_product_H H) (f : ℕ → (Vector ℝ d) → ℝ) (hf : f ∈ H) (df : ℕ → (Vector ℝ d) → ℝ) : ⟪f, ϕ⟫ = ∫ x, ∑ l in range (d + 1), ((d_log_π l x) * (f l x) + df l x) ∂μ :=
by
  rw [h2 f hf ϕ hϕ]
  unfold is_phi at h_is_ϕ
  simp_rw [h_is_ϕ]

  /- First, we get the integral out of the inner product. -/
  have invert_inner_integral : ∀i, ⟪(f i), (fun x ↦ (∫ y, d_log_π i y * k y x + dk y i x ∂μ))⟫ = ∫ y, ⟪(f i), (fun y x ↦ d_log_π i y * k y x + dk y i x) y⟫ ∂μ := fun i ↦ inter_inner_integral_right μ (f i) (fun y x ↦ d_log_π i y * k y x + dk y i x)
  simp_rw [invert_inner_integral]

  /- Then, we switch the integral with the finite sum using *is_integrable_H* assumption. -/
  have invert_sum_integral : ∑ i in range (d + 1), ∫ (y : Vector ℝ d), (fun i y ↦ ⟪f i, fun x ↦ d_log_π i y * k y x + dk y i x⟫) i y ∂μ = ∫ (y : Vector ℝ d), ∑ i in range (d + 1), (fun i y ↦ ⟪f i, fun x ↦ d_log_π i y * k y x + dk y i x⟫) i y ∂μ := by {
    symm
    exact integral_finset_sum (range (d + 1)) (by {
      intros i iin
      exact is_integrable_H ((fun i y ↦ ⟪f i, fun x ↦ d_log_π i y * k y x + dk y i x⟫)) i iin
    })
  }
  simp_rw [invert_sum_integral]

  /- We use the linearity of inner product to develop it and get the constant d_log_π i y out. -/
  have linear_inner : ∀y, ∀i, ⟪f i, fun x ↦ d_log_π i y * k y x + dk y i x⟫ = d_log_π i y * ⟪f i, fun x ↦ k y x⟫ + ⟪f i, fun x ↦ dk y i x⟫ := fun y i ↦ inner_linear_left (f i) (k y) (dk y i) (d_log_π i y)
  simp_rw [linear_inner]

  /- We use reproducing properties of H₀ to rewrite ⟪f i, k y⟫ as f i y and ⟪f i, dk y i⟫ as df i y. -/
  have sum_reproducing : ∀ y, ∑ i in range (d + 1), (d_log_π i y * ⟪f i, fun x => k y x⟫ + ⟪f i, fun x => dk y i x⟫) = ∑ i in range (d + 1), (d_log_π i y * (f i y) + df i y) := by {
    intro y
    have reproducing : ∀ x, ∀ i ∈ range (d + 1), ⟪f i, fun y ↦ k x y⟫ = f i x := by {
      intros x i iin
      symm
      apply h_kernel (f i)
      exact h1 f hf i iin
    }
    apply sum_congr (Eq.refl _)
    intros i iin

    have d_reproducing : ⟪f i, fun x => dk y i x⟫ = df i y := reproducing_derivative H₀ dk (f i) (df) (h1 f hf i iin) y i iin

    rw [reproducing y i iin, d_reproducing]
  }
  simp_rw [sum_reproducing]

/--
  We show that the derivative of the KL is bounded by ‖ϕ‖.
-/
lemma bound_direction (h1 : product_RKHS H H₀) (h2 : inner_product_H H) (f : ℕ → (Vector ℝ d) → ℝ) (hf : f ∈ H) (hfb : ‖f‖ = 1) (df : ℕ → (Vector ℝ d) → ℝ) : ∫ x, ∑ l in range (d + 1), ((d_log_π l x) * (f l x) + df l x) ∂μ ≤ ‖ϕ‖ :=
by
  rw [←inner_product_eq_dKL μ H₀ k h_kernel dk d_log_π ϕ hϕ h_is_ϕ is_integrable_H h1 h2 f hf df]
  calc ⟪f, ϕ⟫ ≤ ‖⟪f, ϕ⟫‖ := le_abs_self ⟪f, ϕ⟫
  _ ≤ ‖f‖ * ‖ϕ‖ := norm_inner_le_norm f ϕ
  _ = ‖ϕ‖ := by {
    rw [hfb]
    simp
  }

/--
We prove that x ↦ ϕ i x / ‖ϕ‖ is the steepest direction for updating the distribution, using ∫ x, ∑ l in range (d + 1), ((d_log_π l x) * (f l x) + df l x) ∂μ = ⟪f, ϕ⟫ ≤ ‖ϕ‖.
-/
theorem steepest_descent_trajectory (h1 : product_RKHS H H₀) (h2 : inner_product_H H) (hϕs : (fun i x ↦ ϕ i x / ‖ϕ‖) ∈ H) : ∫ x, ∑ l in range (d + 1), ((d_log_π l x) * ((fun i x ↦ ϕ i x / ‖ϕ‖) l x) + dϕ l x) ∂μ = ‖ϕ‖ :=
by
  rw [←inner_product_eq_dKL μ H₀ k h_kernel dk d_log_π ϕ hϕ h_is_ϕ is_integrable_H h1 h2 (fun i x ↦ ϕ i x / ‖ϕ‖) hϕs dϕ]

  have div_to_mul : ∀i, ∀x, ϕ i x / ‖ϕ‖ = ϕ i x * (1 / ‖ϕ‖) := fun i x ↦ div_eq_mul_one_div (ϕ i x) ‖ϕ‖
  simp_rw [div_to_mul]

  have linear_inner : ⟪(fun i x => ϕ i x * (1 / ‖ϕ‖)), ϕ⟫ = 1 / ‖ϕ‖ * ⟪(fun i x => ϕ i x), ϕ⟫ + ⟪(fun i x => 0), ϕ⟫ := by {
    have comm : ∀i, ∀x, (1 / ‖ϕ‖) * (ϕ i x) = (ϕ i x) * (1 / ‖ϕ‖) := fun i x ↦ mul_comm (1 / ‖ϕ‖) (ϕ i x)
    simp_rw [←comm]
    have add_zero : ⟪fun i x => 1 / ‖ϕ‖ * ϕ i x, ϕ⟫ = ⟪fun i x => 1 / ‖ϕ‖ * ϕ i x + 0, ϕ⟫ := by {simp}
    rw [add_zero]
    exact inner_linear_right ϕ ϕ (fun i x ↦ 0) (1 / ‖ϕ‖)
  }
  rw [linear_inner]

  have inner_prod_zero : ⟪fun i x ↦ 0, ϕ⟫ = 0 := by {
    exact inner_zero ϕ
  }
  rw[inner_prod_zero, add_zero]

  have eq_re : ⟪fun i x ↦ ϕ i x, ϕ⟫ = re ⟪ϕ, ϕ⟫ := by simp
  rw [eq_re]
  rw [inner_self_eq_norm_mul_norm]
  rw [Mathlib.Tactic.RingNF.mul_assoc_rev (1 / ‖ϕ‖) ‖ϕ‖ ‖ϕ‖]
  simp


/-===============================KERNEL STEIN DISCREPANCY===============================-/
/-
Here, we prove that KSD(μ | π) is a valid discrepancy measure, i.e. KSD(μ | π) = 0 ↔ μ = π.
-/

/- Def of ℝ≥0∞ coerced log. -/
noncomputable def log (a : ℝ≥0∞) := Real.log (ENNReal.toReal a)

/--
 ∀ a ∈ ]0, ∞[, exp (log a) = (a : ℝ).
-/
lemma enn_comp_exp_log (a : ℝ≥0∞) (ha : a ≠ 0) (ha2 : a ≠ ∞) : Real.exp (log a) = ENNReal.toReal a := by
  by_cases ENNReal.toReal a = 0
  {
    exfalso
    have t : a = 0 ∨ a = ∞ := (toReal_eq_zero_iff a).mp h
    cases t with
    | inl hp => exact ha hp
    | inr hq => exact ha2 hq
  }
  {
    push_neg at h
    have t : ENNReal.toReal a ≠ 0 → ENNReal.toReal a < 0 ∨ 0 < ENNReal.toReal a := by {simp}
    specialize t h
    cases t with
    | inl hp => {
      have tt : 0 < ENNReal.toReal a := toReal_pos ha ha2
      linarith
    }
    | inr hq => exact Real.exp_log hq
  }

/--
 ∀ a ∈ ]0, ∞[, log a = (c : ℝ) → a = (exp c : ℝ≥0∞).
-/
lemma cancel_log_exp (a : ℝ≥0∞) (ha : a ≠ 0) (ha2 : a ≠ ∞) (c : ℝ) : log a = c → a = ENNReal.ofReal (Real.exp c) :=
by
  intro h
  rw [←h, enn_comp_exp_log a ha ha2]
  exact Eq.symm (ofReal_toReal ha2)

/--
Definition of infinite limit at infinity for vector-valued function (we use the order of real numbers on the norm of vectors as an order on ℝᵈ).
-/
def tends_to_infty {α : Type _} [Norm α] (f : α → ℝ) := ∀ c > 0, ∃ (x : α), ∀ (x':α), ‖x‖ ≤ ‖x'‖ → c < f x
variable [Norm (Vector ℝ d)]
/--
Unformal but highly pratical multivariate integration by parts.
-/
lemma mv_integration_by_parts (f : Vector ℝ d → ℝ) (g grad_f dg : ℕ → (Vector ℝ d) → ℝ) (h : ∀ x, tends_to_infty (fun (x : Vector ℝ d) ↦ ‖x‖) → ∀i, f x * g i x = 0) : ∫ x in Set.univ, f x * (∑ i in range (d + 1), dg i x) ∂μ = - ∫ x in Set.univ, (∑ i in range (d + 1), grad_f i x * g i x) ∂μ := by sorry

/- Same as before, we will use this assumption only when the function is trivially integrable (e.g. derivative of integrable functions). -/
variable (is_integrable_H₀ : ∀ (f : Vector ℝ d → ℝ), Integrable f μ)

/-
d_log_μ_π : i ↦ c ↦ ∂xⁱ log (μ(x) / π(x))
-/
variable (d_log_μ_π : ℕ → (Vector ℝ d) → ℝ)

variable (d_log_μ_π : ℕ → (Vector ℝ d) → ℝ) (hd_log_μ_π : (∀x, ∀i, d_log_μ_π i x = 0) → (∃ c, ∀ x, log (dμ x / dπ x) = c))

/-
dπ' : i ↦ c ↦ ∂xⁱ π(x)
-/
variable (dπ' : ℕ → (Vector ℝ d) → ℝ) (d_log_π : ℕ → (Vector ℝ d) → ℝ)

/-
Simple derivative rule: ∂xⁱ log (π(x)) * π(x) = ∂xⁱ π(x).
-/
variable (hπ' : ∀x, ∀i, ENNReal.toReal (dπ x) * d_log_π i x = dπ' i x)

/-
  Stein class of measure. f is in the Stein class of μ if, ∀i ∈ range (d + 1), lim_(‖x‖ → ∞) μ(x) * ϕ(x)ⁱ = 0.
-/
def SteinClass (f : ℕ → (Vector ℝ d) → ℝ) (dμ : (Vector ℝ d) → ℝ≥0∞) := ∀ x, tends_to_infty (fun (x : Vector ℝ d) ↦ ‖x‖) → ∀i, ENNReal.toReal (dμ x) * f i x = 0

/--
KSD(μ || π) = ⟪∇log μ/π, Pμ ∇log μ/π⟫_L²(μ). We assume here that KSD is also equal to ∫ x, ∑ l in range (d + 1), (d_log_π l x * ϕ l x + dϕ l x) ∂μ.
-/
lemma ksd : ∫ x in Set.univ, (∫ x' in Set.univ, (∑ i in range (d + 1), d_log_μ_π i x * k x x' * d_log_μ_π i x') ∂μ) ∂μ = ∫ (x : Vector ℝ d), ∑ l in range (d + 1), (d_log_π l x * ϕ l x + dϕ l x) ∂μ := by sorry

/--
We show that, if ϕ is in the Stein class of π, KSD is a valid discrepancy measure i.e. μ = π ↔ KSD(μ || π) = 0.
-/
lemma KSD_is_valid_discrepancy (hstein : SteinClass ϕ dπ) : μ = π ↔ ∫ x in Set.univ, (∫ x' in Set.univ, (∑ i in range (d + 1), d_log_μ_π i x * k x x' * d_log_μ_π i x') ∂μ) ∂μ = 0 :=
by
  constructor
  {
    intro h

    rw [ksd μ k ϕ dϕ d_log_μ_π d_log_π]

    have split_sum : ∀x, ∑ l in range (d + 1), (d_log_π l x * ϕ l x + dϕ l x) = (∑ l in range (d + 1), d_log_π l x * ϕ l x) + (∑ l in range (d + 1), dϕ l x) := fun x ↦ sum_add_distrib
    simp_rw [split_sum]

    have h1 : Integrable (fun x ↦ (∑ l in range (d + 1), d_log_π l x * ϕ l x)) μ := is_integrable_H₀ _
    have h2 : Integrable (fun x ↦ (∑ l in range (d + 1), dϕ l x)) μ := is_integrable_H₀ _
    rw [integral_add (h1) h2]

    have int_univ : ∫ a, ∑ l in range (d + 1), d_log_π l a * ϕ l a ∂μ = ∫ a in Set.univ, ∑ l in range (d + 1), d_log_π l a * ϕ l a ∂μ := by simp
    rw [int_univ]

    rw [h]

    rw [density_integration π ν dπ hπ (fun x ↦ (∑ l in range (d + 1), d_log_π l x * ϕ l x)) Set.univ]

    have mul_dist : ∀x, ENNReal.toReal (dπ x) * (∑ l in range (d + 1), (fun l ↦ d_log_π l x * ϕ l x) l) = ∑ l in range (d + 1), (fun l ↦ d_log_π l x * ϕ l x) l * ENNReal.toReal (dπ x) := by {
      have mul_dist_sum : ∀ (a : ℝ), ∀ (f : ℕ → ℝ), (∑ i in range (d + 1), f i) * a = ∑ i in range (d + 1), f i * a := fun a f ↦ Finset.sum_mul
      intro x
      rw [mul_comm]
      exact mul_dist_sum (ENNReal.toReal (dπ x)) (fun l ↦ d_log_π l x * ϕ l x)
    }
    simp_rw [mul_dist]

    have mul_comm : ∀x, ∀i, d_log_π i x * ϕ i x * ENNReal.toReal (dπ x) = ENNReal.toReal (dπ x) * d_log_π i x * ϕ i x := fun x i ↦ (mul_rotate (ENNReal.toReal (dπ x)) (d_log_π i x) (ϕ i x)).symm
    simp_rw [mul_comm, hπ']

    have int_univ : ∫ a, ∑ l in range (d + 1), dϕ l a ∂π = ∫ a in Set.univ, ∑ l in range (d + 1), dϕ l a ∂π := by simp
    rw [int_univ]
    rw [density_integration π ν dπ hπ (fun x ↦ (∑ l in range (d + 1), dϕ l x)) Set.univ]

    rw [mv_integration_by_parts ν (fun x ↦ ENNReal.toReal (dπ x)) ϕ dπ' dϕ (hstein)]
    simp
  }
  {
    intro h

    have d_log_μ_π_eq_0 := (h_kernel_positive d_log_μ_π).right.mp h
    specialize hd_log_μ_π d_log_μ_π_eq_0

    rcases hd_log_μ_π with ⟨c, h⟩
    have dμ_propor : ∀x, dμ x = ENNReal.ofReal (Real.exp c) * dπ x := by {
      intro x
      specialize h x
      have frac_neq_zero : dμ x / dπ x ≠ 0 := by {
        have frac_pos : 0 < dμ x / dπ x := ENNReal.div_pos_iff.mpr ⟨(hdμ x).left, (hdπ x).right⟩
        exact zero_lt_iff.mp frac_pos
      }

      have frac_finite : dμ x / dπ x ≠ ∞ := by {
        by_contra h
        rw [div_eq_top] at h
        cases h with
          | inl hp => {
            rcases hp with ⟨hpl, hpr⟩
            exact (hdπ x).left hpr
          }
          | inr hq => {
            rcases hq with ⟨hql, hqr⟩
            exact (hdμ x).right hql
          }
      }

      have cancel_log_exp : dμ x / dπ x = ENNReal.ofReal (Real.exp c) := cancel_log_exp (dμ x / dπ x) frac_neq_zero frac_finite c h
      simp [←cancel_log_exp, ENNReal.div_eq_inv_mul, mul_right_comm (dπ x)⁻¹ (dμ x) (dπ x), ENNReal.inv_mul_cancel (hdπ x).left (hdπ x).right]
    }

    have exp_c_eq_one : ENNReal.ofReal (Real.exp c) = 1 := by {
      by_cases hc : ENNReal.ofReal (Real.exp c) = 1
      {assumption}
      {
        push_neg at hc
        have univ_eq_one_μ : ∫⁻ x in Set.univ, 1 ∂μ = 1 := by simp
        have univ_eq_one_π : ∫⁻ x in Set.univ, 1 ∂π = 1 := by simp
        simp_rw [hc, fun x ↦ one_mul (dπ x)] at dμ_propor

        rw [density_lintegration μ ν dμ hμ (fun x ↦ 1) Set.univ] at univ_eq_one_μ
        simp_rw [dμ_propor] at univ_eq_one_μ
        simp_rw [mul_one] at univ_eq_one_μ

        have t : ∫⁻ x in Set.univ, ENNReal.ofReal (Real.exp c) * dπ x ∂ν =  ENNReal.ofReal (Real.exp c) * ∫⁻ x in Set.univ, dπ x ∂ν := lintegral_const_mul (ENNReal.ofReal (Real.exp c)) (mdπ)

        rw [density_lintegration π ν dπ hπ (fun x ↦ 1) Set.univ] at univ_eq_one_π
        simp_rw [mul_one] at univ_eq_one_π
        rw [t, univ_eq_one_π, mul_one] at univ_eq_one_μ
        exfalso
        exact hc univ_eq_one_μ
      }
    }

    simp_rw [exp_c_eq_one, one_mul] at dμ_propor
    ext s _hs
    rw [←set_lintegral_one s, ←set_lintegral_one s]
    rw [density_lintegration μ ν dμ hμ, density_lintegration π ν dπ hπ]
    simp_rw [mul_one, dμ_propor]
  }