"""Independent Python checks, NOT execution of MATLAB or a convergence test.
Run with numpy; optional --forward also needs disba 0.7.0 and its dependencies.
"""
import argparse
import json
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parents[1]


def balance_audit():
    e = np.array([0., .5, 1., 2., 4.])
    prior = np.array([.1, .15, .2, .25, .3])
    cold = prior * np.exp(-e)
    hot = prior * np.exp(-.5*e)
    cold /= cold.sum()
    hot /= hot.sum()
    errors = []
    for edges in ([-np.inf, .7, 3., np.inf], [-np.inf, 1.5, np.inf]):
        b = np.searchsorted(edges, e, side='right') - 1
        P = np.zeros((len(e), len(e)))
        for i in range(len(e)):
            q = hot * (b == b[i])
            q /= q.sum()
            for j in range(len(e)):
                if i != j:
                    P[i, j] = q[j] * np.exp(min(0., .5*(e[i]-e[j])))
            P[i, i] = 1.-P[i].sum()
        flow = cold[:, None] * P
        err = float(np.max(abs(flow-flow.T)))
        assert err < 1e-13
        errors.append(err)
    # Half-open endpoints for finite raw scores.
    assert np.array_equal(np.searchsorted([-np.inf, 1., 2., np.inf], [-100., 1., 2., 100.], side='right')-1, [0, 1, 2, 2])
    return {'ideal_balance_errors': errors, 'finite_history_proof': False}


def data_audit(forward=False):
    # "five" is the retained case label; its current reference model was
    # later changed by the experiment to six physical layers.
    models = {'five': ([400,500,600,300,700,900], [3,5,6,3,10,0]),
              'seven': ([400,450,500,550,600,700,900], [4,5,5,6,7,6,0])}
    results = {}
    for name, (vs, h) in models.items():
        data = np.loadtxt(ROOT/'data'/f'{name}_layer_rayleigh.txt')
        assert data.ndim == 2 and data.shape[1] == 4 and data.shape[0] > 0
        valid = np.isfinite(data[:, 1:])
        assert np.all(data[:, 1:][valid] > 0)
        item = {'shape': list(data.shape), 'valid_points_per_mode': valid.sum(axis=0).tolist()}
        if forward:
            from disba import PhaseDispersion
            vs = np.array(vs, dtype=float)
            vp = 2*vs
            rho = .31*vp**.25
            pd = PhaseDispersion(np.array(h, dtype=float)/1000, vp/1000, vs/1000, rho, algorithm='dunkin', dc=.005)
            periods = np.sort(1./data[:, 0])
            item['modes'] = []
            for mode in range(3):
                curve = pd(periods, mode=mode, wave='rayleigh')
                pred = np.full(data.shape[0], np.nan)
                for period, velocity in zip(curve.period, curve.velocity):
                    idx = np.argmin(abs(data[:,0]-1./period))
                    if abs(data[idx,0]-1./period) <= 1e-6:
                        pred[idx] = velocity*1000
                mask = valid[:,mode]
                assert np.all(np.isfinite(pred[mask])), (name, mode, 'missing root')
                residual = pred[mask]-data[mask,mode+1]
                maximum = float(np.max(abs(residual)))
                assert maximum < .01, (name, mode, maximum)
                item['modes'].append({'mode':mode, 'RMSE_mps':float(np.sqrt(np.mean(residual**2))), 'max_abs_mps':maximum})
        results[name] = item
    return results


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--forward', action='store_true')
    parser.add_argument('--output')
    args = parser.parse_args()
    result = {'kind':'independent Python audit; not MATLAB execution', 'balance':balance_audit(), 'data':data_audit(args.forward)}
    if args.forward:
        import disba, numba, platform
        result['versions'] = {'python':platform.python_version(), 'numpy':np.__version__, 'numba':numba.__version__, 'disba':disba.__version__}
    text = json.dumps(result, ensure_ascii=False, indent=2)
    if args.output:
        Path(args.output).write_text(text+'\n', encoding='utf-8')
    print(text)


if __name__ == '__main__':
    main()
