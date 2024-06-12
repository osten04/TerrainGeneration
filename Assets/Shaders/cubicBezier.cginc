
struct cubicControllPoints
{
    float2 p0;
    float2 p1;
    float2 p2;
    float2 p3;
};

float2 bezierCurve( cubicControllPoints _points, float _t )
{
    float pow2 = _t * _t;
    float pow3 = _t * _t * _t;
    
    float t_inv = 1.0f - _t;
    
    float inv_pow2 = t_inv * t_inv;
    float inv_pow3 = t_inv * t_inv * t_inv;
    
    return inv_pow3 * _points.p0 + 3.0f * inv_pow2 * _t * _points.p1 + 3.0f * t_inv * pow2 * _points.p2 + pow3 * _points.p3;
}

float2 bezierCurveDerivative( cubicControllPoints _points, float _t )
{
    float pow2 = _t * _t;
    
    float t_inv = 1.0f - _t;
    
    float inv_pow2 = t_inv * t_inv;
    
    return 3.0f * inv_pow2 * ( _points.p1 - _points.p0 ) + 6.0f * t_inv * _t * ( _points.p2 - _points.p1 ) + 3.0f * pow2 * ( _points.p3 - _points.p2 );

}
