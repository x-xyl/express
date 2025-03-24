 // 发起微信支付
 weChatPay() {
    let param = {
      appId: this.depositInfo.wx_app_id,
      partnerId: this.depositInfo.wx_mch_account,
      prepayId: this.depositInfo.prepay_id,
      nonceStr: this.depositInfo.nonce_str,
      timeStamp: this.depositInfo.timestamp,
      sign: this.depositInfo.sign
    } as WeChatPayParam
    WeChatTool.wechatPay(param, (resp: PayResp)=>{
      // 校验微信支付结果
      if (resp.errCode != ErrCode.ERR_OK) {
        ShowToastOfHuaWeiPayFault(resp.errStr ?? '支付失败')
        return
      }
      this.checkOrderState()
    })
  }

  export interface WeChatPayParam {
    appId: string, // 填写下单时传入的【公众账号ID】appid。
    partnerId: string // 填写下单时传入的【商户号】mchid。
    prepayId: string // 预支付交易会话标识。APP下单接口返回的prepay_id，该值有效期为2小时，超过有效期需要重新请求APP下单接口以获取新的prepay_id。
    nonceStr: string //  随机字符串，不长于32位。该值建议使用随机数算法生成。
    timeStamp: string //  注意：常见时间戳为秒级或毫秒级，该处必需传秒级时间戳。
    sign: string // 签名，使用字段appId、timeStamp、nonceStr、prepayId以及商户API证书私钥生成的RSA签名值
  }